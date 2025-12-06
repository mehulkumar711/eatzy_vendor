const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const port = 3000;

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir)
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname)
    }
});

const upload = multer({ storage: storage });

app.get('/vendors/me/items', (req, res) => {
    res.json([]);
});

app.post('/vendors/me/items', upload.single('image'), (req, res) => {
    console.log('Received item creation request');
    console.log('Body:', req.body);
    console.log('File:', req.file);

    const newItem = {
        id: 'item_' + Date.now(),
        name: req.body.name,
        price: parseFloat(req.body.price),
        veg: req.body.veg === 'true',
        stock: parseInt(req.body.stock),
        category: req.body.category,
        imageUrl: req.file ? `http://localhost:${port}/uploads/${req.file.filename}` : null
    };

    // Simulate processing time
    setTimeout(() => {
        res.json(newItem);
    }, 500);
});

app.use('/uploads', express.static(uploadDir));

app.listen(port, '0.0.0.0', () => {
    console.log(`Mock upload server listening on port ${port}`);
});
