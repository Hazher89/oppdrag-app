const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { body, validationResult } = require('express-validator');
const Conversation = require('../models/Chat');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/chat';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'chat-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf', 'text/plain'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  }
});

// @route   GET /api/v1/chat/conversations
// @desc    Get user conversations
// @access  Private
router.get('/conversations', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user.id,
      isActive: true
    })
    .populate('participants', 'name phoneNumber role')
    .populate('lastMessage.senderId', 'name')
    .sort({ 'lastMessage.createdAt': -1 });

    // Add unread count for current user
    const conversationsWithUnread = conversations.map(conv => {
      const unreadCount = conv.unreadCount.get(req.user.id.toString()) || 0;
      return {
        ...conv.toObject(),
        unreadCount
      };
    });

    res.json({ conversations: conversationsWithUnread });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/chat/conversations
// @desc    Create or get conversation
// @access  Private
router.post('/conversations', auth, [
  body('participantIds').isArray().withMessage('Participant IDs must be an array'),
  body('title').optional().isString().withMessage('Title must be a string'),
  body('conversationType').optional().isIn(['direct', 'group']).withMessage('Valid conversation type is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { participantIds, title, conversationType = 'direct' } = req.body;

    // Add current user to participants
    const allParticipants = [...new Set([req.user.id, ...participantIds])];

    // Check if participants exist and belong to same company
    const participants = await User.find({
      _id: { $in: participantIds },
      companyId: req.user.companyId,
      isActive: true
    });

    if (participants.length !== participantIds.length) {
      return res.status(400).json({ error: 'Invalid participants' });
    }

    // For direct conversations, check if conversation already exists
    if (conversationType === 'direct' && allParticipants.length === 2) {
      const existingConversation = await Conversation.findOne({
        participants: { $all: allParticipants },
        conversationType: 'direct',
        isActive: true
      });

      if (existingConversation) {
        await existingConversation.populate('participants', 'name phoneNumber role');
        return res.json({ conversation: existingConversation });
      }
    }

    // Create new conversation
    const conversation = new Conversation({
      participants: allParticipants,
      companyId: req.user.companyId,
      conversationType,
      title: title || (conversationType === 'direct' ? participants[0].name : 'Group Chat'),
      adminIds: req.user.role === 'admin' ? [req.user.id] : []
    });

    await conversation.save();
    await conversation.populate('participants', 'name phoneNumber role');

    res.status(201).json({ conversation });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/chat/conversations/:id/messages
// @desc    Get conversation messages
// @access  Private
router.get('/conversations/:id/messages', auth, async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const skip = (page - 1) * limit;

    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Get messages from the conversation
    const messages = await Conversation.aggregate([
      { $match: { _id: conversation._id } },
      { $unwind: '$messages' },
      { $sort: { 'messages.createdAt': -1 } },
      { $skip: skip },
      { $limit: parseInt(limit) },
      {
        $lookup: {
          from: 'users',
          localField: 'messages.senderId',
          foreignField: '_id',
          as: 'sender'
        }
      },
      { $unwind: '$sender' },
      {
        $project: {
          _id: '$messages._id',
          content: '$messages.content',
          messageType: '$messages.messageType',
          fileUrl: '$messages.fileUrl',
          fileName: '$messages.fileName',
          fileSize: '$messages.fileSize',
          location: '$messages.location',
          isRead: '$messages.isRead',
          readAt: '$messages.readAt',
          createdAt: '$messages.createdAt',
          sender: {
            id: '$sender._id',
            name: '$sender.name',
            role: '$sender.role'
          }
        }
      }
    ]);

    // Mark messages as read
    await conversation.markAsRead(req.user.id);

    res.json({
      messages: messages.reverse(),
      pagination: {
        current: parseInt(page),
        hasNext: messages.length === parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/chat/conversations/:id/messages
// @desc    Send message
// @access  Private
router.post('/conversations/:id/messages', auth, upload.single('file'), [
  body('content').notEmpty().withMessage('Message content is required'),
  body('messageType').optional().isIn(['text', 'image', 'file', 'location']).withMessage('Valid message type is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const { content, messageType = 'text', location } = req.body;

    // Create message object
    const messageData = {
      senderId: req.user.id,
      content,
      messageType
    };

    // Handle file upload
    if (req.file) {
      messageData.fileUrl = `${req.protocol}://${req.get('host')}/uploads/chat/${req.file.filename}`;
      messageData.fileName = req.file.originalname;
      messageData.fileSize = req.file.size;
      messageData.messageType = req.file.mimetype.startsWith('image/') ? 'image' : 'file';
    }

    // Handle location
    if (location) {
      messageData.location = JSON.parse(location);
      messageData.messageType = 'location';
    }

    // Add message to conversation
    await conversation.addMessage(messageData);

    // Populate sender info
    const populatedMessage = {
      ...messageData,
      sender: {
        id: req.user.id,
        name: req.user.name,
        role: req.user.role
      },
      createdAt: new Date()
    };

    res.status(201).json({
      message: 'Message sent successfully',
      messageData: populatedMessage
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/chat/conversations/:id/read
// @desc    Mark conversation as read
// @access  Private
router.put('/conversations/:id/read', auth, async (req, res) => {
  try {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await conversation.markAsRead(req.user.id);

    res.json({ message: 'Conversation marked as read' });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/chat/users
// @desc    Get available users for chat
// @access  Private
router.get('/users', auth, async (req, res) => {
  try {
    const users = await User.find({
      companyId: req.user.companyId,
      isActive: true,
      _id: { $ne: req.user.id }
    })
    .select('name phoneNumber role')
    .sort({ name: 1 });

    res.json({ users });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   DELETE /api/v1/chat/conversations/:id
// @desc    Delete conversation
// @access  Private
router.delete('/conversations/:id', auth, async (req, res) => {
  try {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // For group chats, only admins can delete
    if (conversation.conversationType === 'group' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Only admins can delete group conversations' });
    }

    // Soft delete - mark as inactive
    conversation.isActive = false;
    await conversation.save();

    res.json({ message: 'Conversation deleted successfully' });

  } catch (error) {
    console.error('Delete conversation error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 