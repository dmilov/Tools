// ***************************************************************************
// https://github.com/microsoft/Web-Dev-For-Beginners/tree/main/7-bank-project/api
// ***************************************************************************

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors')
const { v4: uuidv4 } = require('uuid');


// App constants
const port = process.env.PORT || 3000;
const apiPrefix = '/api';

// Store data in-memory, not suited for production use!
const db = {
  shoes: [
  {
    id: '309ca04d-adf4-410a-8c6d-ee5b0171aab3',
    brand: 'Mizuno',
    model: 'Wave Rider 27'
  },
  {
    id: 'b97e11c8-ea28-434e-b5a2-94f2b6c383ee',
    brand: 'Saucony',
    model: 'Kinvara 14'
  },
  {
    id: '211ffe25-bf46-4950-a6a0-23a39891183b',
    brand: 'Brooks',
    model: 'Adrenaline GTS 23'
  },
  {
    id: 'f9a7164c-bfa3-4190-9cb0-455036373319',
    brand: 'Nike',
    model: 'Pegasus 40'
  }]
};
  
// Create the Express app & setup middlewares
const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors({ origin: /http:\/\/(127(\.\d){3}|localhost)/}));
app.use(express.static('doc'))
app.options('*', cors());

// ***************************************************************************

// Configure routes
const router = express.Router();

// Hello World for index page
app.get('/', function (req, res) {
    return res.send("Word Copilot Extensibility Demo API");
})

app.get('/api', function (req, res) {
    return res.send("Word Copilot Extensibility Demo API");
})

// ----------------------------------------------
  // List running shoes
  router.get('/shoes/:query?', (req, res) => {
    if (req.query.query) {
      const regex = new RegExp(`.*${req.query.query}.*`, 'i');
      return res.status(200).json(db.shoes.filter(v => {
        return regex.test(v.model) || regex.test(v.brand)
      }));
    }
    return res.status(200).json(db.shoes);
  });

  // Get runng shoes by id
  router.get('/shoes/:id', (req, res) => {
    const shoes = db.shoes.find(v => {
      return v.id === req.params.id
    });
  
    // Check if account exists
    if (!shoes) {
      return res.status(404).json({ error: `Shoes with id ${req.params.id} don't exist` });
    }
  
    return res.json(shoes);
  });

  // Create running shoes
  router.post('/shoes', (req, res) => {
    if (!req.body.model || !req.body.brand) {
      return res.status(400).json({ error: 'Missing parameters' });
    }
    
    const shoes = {id: uuidv4(), model: req.body.model, brand: req.body.brand};
    db.shoes.push(shoes);
  
    return res.status(201).json(shoes);
  });

  // Update running shoes
  router.put('/shoes/:id', (req, res) => {
    if (!req.body.model || !req.body.brand) {
      return res.status(400).json({ error: 'Missing parameters' });
    }

    const shoes = db.shoes.find(v => {
      return v.id === req.params.id
    });

    if (!shoes) {
      return res.status(404).json({ error: `Shoes with id ${req.params.id} don't exist` });
    }

    const selectedShoesIndex = db.shoes.indexOf(shoes);

    db.shoes[selectedShoesIndex].brand = req.body.brand;
    db.shoes[selectedShoesIndex].model = req.body.model;
  
    return res.json(db.shoes[selectedShoesIndex]);
  });

  // Delete running shoes
  router.delete('/shoes/:id', (req, res) => {
    const shoes = db.shoes.find(v => {
      return v.id === req.params.id
    });

    if (!shoes) {
      return res.status(404).json({ error: `Shoes with id ${req.params.id} don't exist` });
    }

    
    const selectedShoesIndex = db.shoes.indexOf(shoes);
    db.shoes.splice(selectedShoesIndex, 1);
  
    return res.sendStatus(204);
  });
  
// ----------------------------------------------
  // ***************************************************************************

// Add 'api` prefix to all routes
app.use(apiPrefix, router);

// Start the server
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
  
