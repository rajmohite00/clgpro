const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
    id: {
        type: String,
        required: true,
        unique: true
    },
    applicant: {
        type: String,
        default: 'Unknown'
    },
    categoryKey: {
        type: String,
        required: true
    },
    categoryTitle: {
        type: String,
        required: true
    },
    documents: {
        type: Array,
        default: []
    },
    detectionResult: {
        type: Object,
        default: {}
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending'
    },
    submittedBy: {
        type: String,
        required: true
    },
    officerNote: {
        type: String,
        default: null
    },
    decidedBy: {
        type: String,
        default: null
    },
    decidedAt: {
        type: Date,
        default: null
    }
}, { timestamps: true });

module.exports = mongoose.model('Submission', submissionSchema);
