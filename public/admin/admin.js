// Admin Interface JavaScript
let currentUser = null;
let authToken = localStorage.getItem('authToken');

// API Configuration
const API_BASE = window.location.origin + '/api/v1';

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    if (authToken) {
        checkAuth();
    } else {
        showLogin();
    }
});

// Authentication
async function checkAuth() {
    try {
        const response = await fetch(`${API_BASE}/auth/me`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            currentUser = data.user;
            showDashboard();
            loadDashboardData();
        } else {
            localStorage.removeItem('authToken');
            showLogin();
        }
    } catch (error) {
        console.error('Auth check failed:', error);
        showLogin();
    }
}

async function login() {
    const phone = document.getElementById('loginPhone').value;
    const password = document.getElementById('loginPassword').value;

    try {
        const response = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ phoneNumber: phone, password: password })
        });

        const data = await response.json();

        if (response.ok) {
            authToken = data.token;
            currentUser = data.user;
            localStorage.setItem('authToken', authToken);
            showDashboard();
            loadDashboardData();
        } else {
            alert(data.error || 'Login failed');
        }
    } catch (error) {
        console.error('Login error:', error);
        alert('Login failed. Please try again.');
    }
}

function logout() {
    localStorage.removeItem('authToken');
    authToken = null;
    currentUser = null;
    showLogin();
}

// Navigation
function showLogin() {
    hideAllSections();
    document.getElementById('loginForm').style.display = 'block';
}

function showDashboard() {
    hideAllSections();
    document.getElementById('dashboard').style.display = 'block';
    document.getElementById('userName').textContent = currentUser?.name || 'Admin';
}

function showAssignments() {
    hideAllSections();
    document.getElementById('assignments').style.display = 'block';
    loadDrivers();
    loadAssignments();
}

function showDrivers() {
    hideAllSections();
    document.getElementById('drivers').style.display = 'block';
    loadDrivers();
}

function showReports() {
    hideAllSections();
    document.getElementById('reports').style.display = 'block';
    loadReports();
}

function hideAllSections() {
    document.getElementById('loginForm').style.display = 'none';
    document.getElementById('dashboard').style.display = 'none';
    document.getElementById('assignments').style.display = 'none';
    document.getElementById('drivers').style.display = 'none';
    document.getElementById('reports').style.display = 'none';
}

// Dashboard
async function loadDashboardData() {
    try {
        const response = await fetch(`${API_BASE}/admin/dashboard`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            updateDashboardStats(data.stats);
            updateRecentAssignments(data.recentAssignments);
        }
    } catch (error) {
        console.error('Failed to load dashboard data:', error);
    }
}

function updateDashboardStats(stats) {
    document.getElementById('totalDrivers').textContent = stats.totalDrivers;
    document.getElementById('pendingAssignments').textContent = stats.pendingAssignments;
    document.getElementById('inProgressAssignments').textContent = stats.inProgressAssignments;
    document.getElementById('completedAssignments').textContent = stats.completedAssignments;
}

function updateRecentAssignments(assignments) {
    const table = document.getElementById('recentAssignmentsTable');
    
    if (assignments.length === 0) {
        table.innerHTML = '<p class="text-muted">No recent assignments</p>';
        return;
    }

    let html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Driver</th>
                        <th>Status</th>
                        <th>Priority</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
    `;

    assignments.forEach(assignment => {
        html += `
            <tr>
                <td>${assignment.title}</td>
                <td>${assignment.driverId?.name || 'N/A'}</td>
                <td><span class="status-badge status-${assignment.status}">${assignment.status}</span></td>
                <td><span class="badge bg-${getPriorityColor(assignment.priority)}">${assignment.priority}</span></td>
                <td>${new Date(assignment.createdAt).toLocaleDateString()}</td>
            </tr>
        `;
    });

    html += '</tbody></table></div>';
    table.innerHTML = html;
}

// Assignments
async function loadAssignments() {
    try {
        const statusFilter = document.getElementById('statusFilter').value;
        const driverFilter = document.getElementById('driverFilter').value;
        const priorityFilter = document.getElementById('priorityFilter').value;

        let url = `${API_BASE}/assignments?`;
        if (statusFilter) url += `status=${statusFilter}&`;
        if (driverFilter) url += `driverId=${driverFilter}&`;
        if (priorityFilter) url += `priority=${priorityFilter}&`;

        const response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            displayAssignments(data.assignments);
        }
    } catch (error) {
        console.error('Failed to load assignments:', error);
    }
}

function displayAssignments(assignments) {
    const table = document.getElementById('assignmentsTable');
    
    if (assignments.length === 0) {
        table.innerHTML = '<p class="text-muted">No assignments found</p>';
        return;
    }

    let html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Driver</th>
                        <th>Status</th>
                        <th>Priority</th>
                        <th>Pickup Time</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
    `;

    assignments.forEach(assignment => {
        html += `
            <tr>
                <td>${assignment.title}</td>
                <td>${assignment.driverId?.name || 'N/A'}</td>
                <td><span class="status-badge status-${assignment.status}">${assignment.status}</span></td>
                <td><span class="badge bg-${getPriorityColor(assignment.priority)}">${assignment.priority}</span></td>
                <td>${assignment.scheduledPickupTime ? new Date(assignment.scheduledPickupTime).toLocaleString() : 'N/A'}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="viewAssignment('${assignment._id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-warning" onclick="editAssignment('${assignment._id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteAssignment('${assignment._id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table></div>';
    table.innerHTML = html;
}

// Drivers
async function loadDrivers() {
    try {
        const response = await fetch(`${API_BASE}/users/drivers`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            displayDrivers(data.drivers);
            populateDriverSelects(data.drivers);
        }
    } catch (error) {
        console.error('Failed to load drivers:', error);
    }
}

function displayDrivers(drivers) {
    const table = document.getElementById('driversTable');
    
    if (drivers.length === 0) {
        table.innerHTML = '<p class="text-muted">No drivers found</p>';
        return;
    }

    let html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Phone</th>
                        <th>License</th>
                        <th>Vehicle</th>
                        <th>Last Login</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
    `;

    drivers.forEach(driver => {
        html += `
            <tr>
                <td>${driver.name}</td>
                <td>${driver.phoneNumber}</td>
                <td>${driver.licenseNumber || 'N/A'}</td>
                <td>${driver.vehicleId || 'N/A'}</td>
                <td>${driver.lastLogin ? new Date(driver.lastLogin).toLocaleString() : 'Never'}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="viewDriver('${driver._id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-warning" onclick="editDriver('${driver._id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table></div>';
    table.innerHTML = html;
}

function populateDriverSelects(drivers) {
    const driverSelects = ['assignmentDriver', 'driverFilter'];
    
    driverSelects.forEach(selectId => {
        const select = document.getElementById(selectId);
        if (select) {
            select.innerHTML = '<option value="">Select Driver</option>';
            drivers.forEach(driver => {
                select.innerHTML += `<option value="${driver._id}">${driver.name} (${driver.phoneNumber})</option>`;
            });
        }
    });
}

// Create Assignment
function showCreateAssignmentModal() {
    const modal = new bootstrap.Modal(document.getElementById('createAssignmentModal'));
    modal.show();
}

async function createAssignment() {
    const formData = new FormData();
    
    formData.append('title', document.getElementById('assignmentTitle').value);
    formData.append('description', document.getElementById('assignmentDescription').value);
    formData.append('driverId', document.getElementById('assignmentDriver').value);
    formData.append('priority', document.getElementById('assignmentPriority').value);
    formData.append('pickupLocation', document.getElementById('pickupLocation').value);
    formData.append('deliveryLocation', document.getElementById('deliveryLocation').value);
    formData.append('notes', document.getElementById('assignmentNotes').value);
    
    const pickupTime = document.getElementById('pickupTime').value;
    const deliveryTime = document.getElementById('deliveryTime').value;
    
    if (pickupTime) formData.append('scheduledPickupTime', pickupTime);
    if (deliveryTime) formData.append('scheduledDeliveryTime', deliveryTime);
    
    const pdfFile = document.getElementById('assignmentPdf').files[0];
    if (pdfFile) {
        formData.append('pdfFile', pdfFile);
    }

    try {
        const response = await fetch(`${API_BASE}/assignments`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`
            },
            body: formData
        });

        const data = await response.json();

        if (response.ok) {
            alert('Assignment created successfully!');
            bootstrap.Modal.getInstance(document.getElementById('createAssignmentModal')).hide();
            document.getElementById('createAssignmentForm').reset();
            loadAssignments();
        } else {
            alert(data.error || 'Failed to create assignment');
        }
    } catch (error) {
        console.error('Create assignment error:', error);
        alert('Failed to create assignment. Please try again.');
    }
}

// Create Driver
function showCreateDriverModal() {
    const modal = new bootstrap.Modal(document.getElementById('createDriverModal'));
    modal.show();
}

async function createDriver() {
    const driverData = {
        name: document.getElementById('driverName').value,
        phoneNumber: document.getElementById('driverPhone').value,
        email: document.getElementById('driverEmail').value,
        licenseNumber: document.getElementById('driverLicense').value,
        vehicleId: document.getElementById('driverVehicle').value,
        password: document.getElementById('driverPassword').value,
        role: 'driver',
        companyId: currentUser.companyId
    };

    try {
        const response = await fetch(`${API_BASE}/admin/users`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(driverData)
        });

        const data = await response.json();

        if (response.ok) {
            alert('Driver created successfully!');
            bootstrap.Modal.getInstance(document.getElementById('createDriverModal')).hide();
            document.getElementById('createDriverForm').reset();
            loadDrivers();
        } else {
            alert(data.error || 'Failed to create driver');
        }
    } catch (error) {
        console.error('Create driver error:', error);
        alert('Failed to create driver. Please try again.');
    }
}

// Reports
async function loadReports() {
    try {
        const response = await fetch(`${API_BASE}/admin/reports`, {
            headers: {
                'Authorization': `Bearer ${authToken}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            displayReports(data);
        }
    } catch (error) {
        console.error('Failed to load reports:', error);
    }
}

function displayReports(data) {
    // Driver Performance Chart
    const driverCtx = document.getElementById('driverPerformanceChart');
    if (driverCtx) {
        new Chart(driverCtx, {
            type: 'bar',
            data: {
                labels: data.driverPerformance.map(d => d.driverName),
                datasets: [{
                    label: 'Completion Rate (%)',
                    data: data.driverPerformance.map(d => d.completionRate),
                    backgroundColor: 'rgba(102, 126, 234, 0.8)'
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }

    // Assignment Status Chart
    const statusCtx = document.getElementById('assignmentStatusChart');
    if (statusCtx) {
        new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: ['Completed', 'In Progress', 'Pending', 'Cancelled'],
                datasets: [{
                    data: [
                        data.assignmentStats.completedAssignments,
                        data.assignmentStats.inProgressAssignments || 0,
                        data.assignmentStats.pendingAssignments || 0,
                        data.assignmentStats.cancelledAssignments
                    ],
                    backgroundColor: [
                        '#28a745',
                        '#17a2b8',
                        '#ffc107',
                        '#dc3545'
                    ]
                }]
            },
            options: {
                responsive: true
            }
        });
    }
}

// Utility Functions
function getPriorityColor(priority) {
    switch (priority) {
        case 'low': return 'success';
        case 'medium': return 'primary';
        case 'high': return 'warning';
        case 'urgent': return 'danger';
        default: return 'secondary';
    }
}

// Event Listeners
document.getElementById('loginFormElement').addEventListener('submit', function(e) {
    e.preventDefault();
    login();
});

// Placeholder functions for future implementation
function viewAssignment(id) {
    alert('View assignment: ' + id);
}

function editAssignment(id) {
    alert('Edit assignment: ' + id);
}

function deleteAssignment(id) {
    if (confirm('Are you sure you want to delete this assignment?')) {
        alert('Delete assignment: ' + id);
    }
}

function viewDriver(id) {
    alert('View driver: ' + id);
}

function editDriver(id) {
    alert('Edit driver: ' + id);
} 