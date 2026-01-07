const express = require('express');
const { createReview, getReviews } = require('../controllers/review.controller');
const { protect } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/', getReviews);
router.post('/', protect, createReview);

module.exports = router;
