const mongoose = require('mongoose');
const MONGO_URI = process.env.MONGO_URI;
const conectarDB = async () => {
  try {
    await mongoose.connect(MONGO_URI
, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log("✅ Conectado correctamente a MongoDB Atlas");
  } catch (error) {
    console.error("❌ Error al conectar a MongoDB:", error);
    process.exit(1);
  }
};

module.exports = conectarDB;
