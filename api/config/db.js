const mongoose = require('mongoose');

const conectarDB = async () => {
  try {
    await mongoose.connect("mongodb+srv://admin:ETjJmZCNc7m4l86t@cluster0.ivcsn4e.mongodb.net/usuario?appName=Cluster0"
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
