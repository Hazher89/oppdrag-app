// Global variables
let currentUser = null;
let assignments = [];
let drivers = [];
let conversations = [];
let currentConversation = null;

// API Configuration
const API_BASE_URL = 'https://your-api-domain.com/api/v1';

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

async function initializeApp() {
    // Check authentication
    const token = localStorage.getItem('authToken');
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    // Load initial data
    await Promise.all([
        loadDashboardData(),
        loadAssignments(),
        loadDrivers(),
        loadConversations()
    ]);

    // Set up real-time updates
    setupWebSocket();
}

// Navigation
function showSection(sectionId) {
    // Hide all sections
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });

    // Remove active class from all nav items
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });

    // Show selected section
    document.getElementById(sectionId).classList.add('active');

    // Add active class to clicked nav item
    event.currentTarget.classList.add('active');
}

// Dashboard Functions
async function loadDashboardData() {
    try {
        const response = await fetch(`${API_BASE_URL}/dashboard`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            updateDashboardStats(data);
            updateRecentActivity(data.recentActivity);
        }
    } catch (error) {
        console.error('Error loading dashboard data:', error);
        // Load demo data for development
        loadDemoDashboardData();
    }
}

function updateDashboardStats(data) {
    document.getElementById('totalAssignments').textContent = data.totalAssignments || 0;
    document.getElementById('activeDrivers').textContent = data.activeDrivers || 0;
    document.getElementById('pendingAssignments').textContent = data.pendingAssignments || 0;
    document.getElementById('completedAssignments').textContent = data.completedAssignments || 0;
}

function updateRecentActivity(activities) {
    const activityList = document.getElementById('activityList');
    activityList.innerHTML = '';

    if (!activities || activities.length === 0) {
        activityList.innerHTML = '<div class="loading">No recent activity</div>';
        return;
    }

    activities.forEach(activity => {
        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item';
        activityItem.innerHTML = `
            <div class="activity-icon">
                <i class="fas ${getActivityIcon(activity.type)}"></i>
            </div>
            <div class="activity-content">
                <h4>${activity.title}</h4>
                <p>${activity.description} - ${formatTime(activity.timestamp)}</p>
            </div>
        `;
        activityList.appendChild(activityItem);
    });
}

function getActivityIcon(type) {
    const icons = {
        'assignment_created': 'fa-plus-circle',
        'assignment_completed': 'fa-check-circle',
        'driver_joined': 'fa-user-plus',
        'message_sent': 'fa-comment'
    };
    return icons[type] || 'fa-info-circle';
}

// Assignment Functions
async function loadAssignments() {
    try {
        const response = await fetch(`${API_BASE_URL}/assignments`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            }
        });

        if (response.ok) {
            assignments = await response.json();
            renderAssignmentsTable();
        }
    } catch (error) {
        console.error('Error loading assignments:', error);
        // Load demo data for development
        loadDemoAssignments();
    }
}

function renderAssignmentsTable() {
    const tbody = document.getElementById('assignmentsTableBody');
    tbody.innerHTML = '';

    assignments.forEach(assignment => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${assignment.title}</td>
            <td>${assignment.driverName || 'Unassigned'}</td>
            <td>${formatDate(assignment.date)}</td>
            <td><span class="status-badge status-${assignment.status}">${formatStatus(assignment.status)}</span></td>
            <td>${assignment.arrivalTime ? formatTime(assignment.arrivalTime) : 'Not set'}</td>
            <td>
                <button onclick="viewAssignment('${assignment.id}')" class="btn-secondary">View</button>
                <button onclick="editAssignment('${assignment.id}')" class="btn-secondary">Edit</button>
                <button onclick="deleteAssignment('${assignment.id}')" class="btn-secondary">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function filterAssignments() {
    const statusFilter = document.getElementById('statusFilter').value;
    const dateFilter = document.getElementById('dateFilter').value;

    const filtered = assignments.filter(assignment => {
        const statusMatch = !statusFilter || assignment.status === statusFilter;
        const dateMatch = !dateFilter || assignment.date.startsWith(dateFilter);
        return statusMatch && dateMatch;
    });

    renderFilteredAssignments(filtered);
}

function renderFilteredAssignments(filteredAssignments) {
    const tbody = document.getElementById('assignmentsTableBody');
    tbody.innerHTML = '';

    filteredAssignments.forEach(assignment => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${assignment.title}</td>
            <td>${assignment.driverName || 'Unassigned'}</td>
            <td>${formatDate(assignment.date)}</td>
            <td><span class="status-badge status-${assignment.status}">${formatStatus(assignment.status)}</span></td>
            <td>${assignment.arrivalTime ? formatTime(assignment.arrivalTime) : 'Not set'}</td>
            <td>
                <button onclick="viewAssignment('${assignment.id}')" class="btn-secondary">View</button>
                <button onclick="editAssignment('${assignment.id}')" class="btn-secondary">Edit</button>
                <button onclick="deleteAssignment('${assignment.id}')" class="btn-secondary">Delete</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function clearFilters() {
    document.getElementById('statusFilter').value = '';
    document.getElementById('dateFilter').value = '';
    renderAssignmentsTable();
}

// Assignment Modal Functions
function showCreateAssignmentModal() {
    document.getElementById('createAssignmentModal').style.display = 'block';
    loadDriversForSelect();
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

async function createAssignment(event) {
    event.preventDefault();

    const formData = new FormData();
    formData.append('title', document.getElementById('assignmentTitle').value);
    formData.append('description', document.getElementById('assignmentDescription').value);
    formData.append('driverId', document.getElementById('assignmentDriver').value);
    formData.append('date', document.getElementById('assignmentDate').value);
    formData.append('pdf', document.getElementById('assignmentPDF').files[0]);

    try {
        const response = await fetch(`${API_BASE_URL}/assignments`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            },
            body: formData
        });

        if (response.ok) {
            closeModal('createAssignmentModal');
            document.getElementById('assignmentForm').reset();
            await loadAssignments();
            showNotification('Assignment created successfully!', 'success');
        } else {
            throw new Error('Failed to create assignment');
        }
    } catch (error) {
        console.error('Error creating assignment:', error);
        showNotification('Failed to create assignment', 'error');
    }
}

// Driver Functions
async function loadDrivers() {
    try {
        const response = await fetch(`${API_BASE_URL}/drivers`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            }
        });

        if (response.ok) {
            drivers = await response.json();
            renderDriversGrid();
        }
    } catch (error) {
        console.error('Error loading drivers:', error);
        // Load demo data for development
        loadDemoDrivers();
    }
}

function renderDriversGrid() {
    const grid = document.getElementById('driversGrid');
    grid.innerHTML = '';

    drivers.forEach(driver => {
        const card = document.createElement('div');
        card.className = 'driver-card';
        card.innerHTML = `
            <div class="driver-header">
                <div class="driver-avatar">${driver.name.charAt(0)}</div>
                <div class="driver-info">
                    <h4>${driver.name}</h4>
                    <p>${driver.phoneNumber}</p>
                </div>
            </div>
            <div class="driver-stats">
                <div class="stat">
                    <div class="stat-value">${driver.completedAssignments || 0}</div>
                    <div class="stat-label">Completed</div>
                </div>
                <div class="stat">
                    <div class="stat-value">${driver.activeAssignments || 0}</div>
                    <div class="stat-label">Active</div>
                </div>
                <div class="stat">
                    <div class="stat-value">${driver.rating || 'N/A'}</div>
                    <div class="stat-label">Rating</div>
                </div>
            </div>
        `;
        grid.appendChild(card);
    });
}

function showCreateDriverModal() {
    document.getElementById('createDriverModal').style.display = 'block';
}

async function createDriver(event) {
    event.preventDefault();

    const driverData = {
        name: document.getElementById('driverName').value,
        phoneNumber: document.getElementById('driverPhone').value,
        email: document.getElementById('driverEmail').value
    };

    try {
        const response = await fetch(`${API_BASE_URL}/drivers`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            },
            body: JSON.stringify(driverData)
        });

        if (response.ok) {
            closeModal('createDriverModal');
            document.getElementById('driverForm').reset();
            await loadDrivers();
            showNotification('Driver added successfully!', 'success');
        } else {
            throw new Error('Failed to add driver');
        }
    } catch (error) {
        console.error('Error creating driver:', error);
        showNotification('Failed to add driver', 'error');
    }
}

// Chat Functions
async function loadConversations() {
    try {
        const response = await fetch(`${API_BASE_URL}/chat/conversations`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            }
        });

        if (response.ok) {
            conversations = await response.json();
            renderConversationsList();
        }
    } catch (error) {
        console.error('Error loading conversations:', error);
        // Load demo data for development
        loadDemoConversations();
    }
}

function renderConversationsList() {
    const list = document.getElementById('conversationsList');
    list.innerHTML = '';

    conversations.forEach(conversation => {
        const item = document.createElement('div');
        item.className = 'conversation-item';
        item.onclick = () => selectConversation(conversation.id);
        item.innerHTML = `
            <div class="conversation-name">${conversation.title}</div>
            <div class="conversation-preview">${conversation.lastMessage}</div>
        `;
        list.appendChild(item);
    });
}

async function selectConversation(conversationId) {
    currentConversation = conversationId;
    
    // Update UI
    document.querySelectorAll('.conversation-item').forEach(item => {
        item.classList.remove('active');
    });
    event.currentTarget.classList.add('active');

    // Load messages
    await loadMessages(conversationId);
}

async function loadMessages(conversationId) {
    try {
        const response = await fetch(`${API_BASE_URL}/chat/conversations/${conversationId}/messages`, {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            }
        });

        if (response.ok) {
            const messages = await response.json();
            renderMessages(messages);
        }
    } catch (error) {
        console.error('Error loading messages:', error);
    }
}

function renderMessages(messages) {
    const container = document.getElementById('chatMessages');
    container.innerHTML = '';

    messages.forEach(message => {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${message.senderId === currentUser?.id ? 'sent' : ''}`;
        messageDiv.innerHTML = `
            <div class="message-content">
                <div>${message.content}</div>
                <div class="message-time">${formatTime(message.timestamp)}</div>
            </div>
        `;
        container.appendChild(messageDiv);
    });

    // Scroll to bottom
    container.scrollTop = container.scrollHeight;
}

function handleMessageKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

async function sendMessage() {
    const input = document.getElementById('messageInput');
    const content = input.value.trim();

    if (!content || !currentConversation) return;

    try {
        const response = await fetch(`${API_BASE_URL}/chat/conversations/${currentConversation}/messages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('authToken')}`
            },
            body: JSON.stringify({ content })
        });

        if (response.ok) {
            input.value = '';
            await loadMessages(currentConversation);
        }
    } catch (error) {
        console.error('Error sending message:', error);
    }
}

// WebSocket Setup
function setupWebSocket() {
    const ws = new WebSocket('wss://your-websocket-server.com/ws');
    
    ws.onopen = function() {
        console.log('WebSocket connected');
    };
    
    ws.onmessage = function(event) {
        const data = JSON.parse(event.data);
        handleWebSocketMessage(data);
    };
    
    ws.onclose = function() {
        console.log('WebSocket disconnected');
        // Attempt to reconnect after 5 seconds
        setTimeout(setupWebSocket, 5000);
    };
}

function handleWebSocketMessage(data) {
    switch (data.type) {
        case 'new_assignment':
            loadAssignments();
            showNotification('New assignment received!', 'info');
            break;
        case 'assignment_updated':
            loadAssignments();
            break;
        case 'new_message':
            if (data.conversationId === currentConversation) {
                loadMessages(currentConversation);
            }
            showNotification('New message received!', 'info');
            break;
    }
}

// Utility Functions
function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
}

function formatTime(dateString) {
    return new Date(dateString).toLocaleTimeString();
}

function formatStatus(status) {
    const statusMap = {
        'pending': 'Pending',
        'in_progress': 'In Progress',
        'completed': 'Completed'
    };
    return statusMap[status] || status;
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Add to page
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.remove();
    }, 3000);
}

function logout() {
    localStorage.removeItem('authToken');
    window.location.href = 'login.html';
}

// Demo Data Functions (for development)
function loadDemoDashboardData() {
    updateDashboardStats({
        totalAssignments: 15,
        activeDrivers: 8,
        pendingAssignments: 3,
        completedAssignments: 12
    });

    updateRecentActivity([
        {
            type: 'assignment_created',
            title: 'New Assignment Created',
            description: 'Morning route assigned to John Doe',
            timestamp: new Date().toISOString()
        },
        {
            type: 'assignment_completed',
            title: 'Assignment Completed',
            description: 'Downtown delivery completed by Jane Smith',
            timestamp: new Date(Date.now() - 3600000).toISOString()
        }
    ]);
}

function loadDemoAssignments() {
    assignments = [
        {
            id: '1',
            title: 'Morning Route - Downtown',
            driverName: 'John Doe',
            date: '2025-01-15',
            status: 'pending',
            arrivalTime: null
        },
        {
            id: '2',
            title: 'Afternoon Route - Suburbs',
            driverName: 'Jane Smith',
            date: '2025-01-15',
            status: 'in_progress',
            arrivalTime: '2025-01-15T14:00:00Z'
        }
    ];
    renderAssignmentsTable();
}

function loadDemoDrivers() {
    drivers = [
        {
            id: '1',
            name: 'John Doe',
            phoneNumber: '+1234567890',
            completedAssignments: 25,
            activeAssignments: 2,
            rating: 4.8
        },
        {
            id: '2',
            name: 'Jane Smith',
            phoneNumber: '+0987654321',
            completedAssignments: 18,
            activeAssignments: 1,
            rating: 4.9
        }
    ];
    renderDriversGrid();
}

function loadDemoConversations() {
    conversations = [
        {
            id: '1',
            title: 'General Team Chat',
            lastMessage: 'Meeting tomorrow at 9 AM'
        },
        {
            id: '2',
            title: 'Dispatch Office',
            lastMessage: 'Your route has been updated'
        }
    ];
    renderConversationsList();
}

// Close modals when clicking outside
window.onclick = function(event) {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
} 