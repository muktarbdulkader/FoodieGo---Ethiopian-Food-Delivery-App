/**
 * Table Controller - For QR-based dine-in ordering
 */
const Table = require('../models/Table');
const crypto = require('crypto');

// Generate unique QR code data
const generateQRCodeData = (restaurantId, tableId) => {
  // For web app, use HTTP URL instead of deep link
  const baseUrl = process.env.WEB_APP_URL || 'http://localhost:5173';
  return `${baseUrl}/dine-in-menu?restaurantId=${restaurantId}&tableId=${tableId}`;
};

// Get all tables for a restaurant
const getAllTables = async (req, res, next) => {
  try {
    const { restaurantId } = req.query;
    
    // If restaurant user, only show their tables
    const filter = {};
    if (req.user.role === 'restaurant') {
      filter.restaurantId = req.user._id;
    } else if (restaurantId) {
      filter.restaurantId = restaurantId;
    }

    const tables = await Table.find(filter)
      .populate('currentSession.customerId', 'name email phone')
      .sort({ tableNumber: 1 });

    res.json({ success: true, count: tables.length, data: tables });
  } catch (error) {
    next(error);
  }
};

// Get single table by ID
const getTableById = async (req, res, next) => {
  try {
    const table = await Table.findById(req.params.id)
      .populate('restaurantId', 'hotelName hotelAddress hotelPhone hotelImage')
      .populate('currentSession.customerId', 'name email phone');

    if (!table) {
      return res.status(404).json({ success: false, message: 'Table not found' });
    }

    res.json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// Get table by QR scan data
const getTableByQRCode = async (req, res, next) => {
  try {
    const { restaurantId, tableId } = req.query;

    if (!restaurantId || !tableId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Restaurant ID and Table ID are required' 
      });
    }

    const table = await Table.findOne({ 
      _id: tableId, 
      restaurantId,
      isActive: true 
    }).populate('restaurantId', 'hotelName hotelAddress hotelPhone hotelImage isOpen deliveryFee');

    if (!table) {
      return res.status(404).json({ 
        success: false, 
        message: 'Table not found or inactive' 
      });
    }

    res.json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// Create table (restaurant only)
const createTable = async (req, res, next) => {
  try {
    const { tableNumber, capacity, location } = req.body;

    // Check if table number already exists for this restaurant
    const existingTable = await Table.findOne({
      restaurantId: req.user._id,
      tableNumber
    });

    if (existingTable) {
      return res.status(400).json({ 
        success: false, 
        message: 'Table number already exists' 
      });
    }

    // Create table with temporary ID for QR code generation
    const table = new Table({
      restaurantId: req.user._id,
      tableNumber,
      capacity: capacity || 4,
      location: location || '',
      qrCodeData: 'temp' // Temporary value
    });

    await table.save();

    // Generate QR code data with actual table ID
    table.qrCodeData = generateQRCodeData(req.user._id, table._id);
    await table.save();

    res.status(201).json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// Update table (restaurant only)
const updateTable = async (req, res, next) => {
  try {
    const { tableNumber, capacity, location, isActive } = req.body;

    const table = await Table.findOneAndUpdate(
      { _id: req.params.id, restaurantId: req.user._id },
      { tableNumber, capacity, location, isActive },
      { new: true, runValidators: true }
    );

    if (!table) {
      return res.status(404).json({ 
        success: false, 
        message: 'Table not found or not authorized' 
      });
    }

    res.json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// Delete table (restaurant only)
const deleteTable = async (req, res, next) => {
  try {
    const table = await Table.findOneAndDelete({
      _id: req.params.id,
      restaurantId: req.user._id
    });

    if (!table) {
      return res.status(404).json({ 
        success: false, 
        message: 'Table not found or not authorized' 
      });
    }

    res.json({ success: true, message: 'Table deleted' });
  } catch (error) {
    next(error);
  }
};

// Start table session (when customer scans QR)
const startTableSession = async (req, res, next) => {
  try {
    const { tableId } = req.params;

    const table = await Table.findById(tableId);

    if (!table) {
      return res.status(404).json({ success: false, message: 'Table not found' });
    }

    // Update session
    table.currentSession = {
      isOccupied: true,
      customerId: req.user._id,
      startTime: new Date(),
      orderIds: []
    };

    await table.save();

    res.json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// End table session
const endTableSession = async (req, res, next) => {
  try {
    const { tableId } = req.params;

    const table = await Table.findById(tableId);

    if (!table) {
      return res.status(404).json({ success: false, message: 'Table not found' });
    }

    // Clear session
    table.currentSession = {
      isOccupied: false,
      customerId: null,
      startTime: null,
      orderIds: []
    };

    await table.save();

    res.json({ success: true, message: 'Table session ended' });
  } catch (error) {
    next(error);
  }
};

// Add order to table session
const addOrderToTable = async (req, res, next) => {
  try {
    const { tableId, orderId } = req.body;

    const table = await Table.findById(tableId);

    if (!table) {
      return res.status(404).json({ success: false, message: 'Table not found' });
    }

    // Add order to session
    if (!table.currentSession.orderIds.includes(orderId)) {
      table.currentSession.orderIds.push(orderId);
      await table.save();
    }

    res.json({ success: true, data: table });
  } catch (error) {
    next(error);
  }
};

// Bulk create tables for a restaurant
const bulkCreateTables = async (req, res, next) => {
  try {
    const { count, prefix, capacity, location } = req.body;

    if (!count || count < 1 || count > 100) {
      return res.status(400).json({ 
        success: false, 
        message: 'Count must be between 1 and 100' 
      });
    }

    const tables = [];
    for (let i = 1; i <= count; i++) {
      const tableNumber = `${prefix || 'T'}${String(i).padStart(2, '0')}`;
      
      // Check if table already exists
      const exists = await Table.findOne({
        restaurantId: req.user._id,
        tableNumber
      });

      if (!exists) {
        const table = new Table({
          restaurantId: req.user._id,
          tableNumber,
          capacity: capacity || 4,
          location: location || '',
          qrCodeData: 'temp'
        });

        await table.save();
        table.qrCodeData = generateQRCodeData(req.user._id, table._id);
        await table.save();
        tables.push(table);
      }
    }

    res.status(201).json({ 
      success: true, 
      count: tables.length,
      data: tables 
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllTables,
  getTableById,
  getTableByQRCode,
  createTable,
  updateTable,
  deleteTable,
  startTableSession,
  endTableSession,
  addOrderToTable,
  bulkCreateTables
};
