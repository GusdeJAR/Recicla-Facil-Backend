const nodemailer = require('nodemailer');

async function enviarCorreo(destinatario, asunto, texto) {
    // Configura el transporte SMTP (puedes usar Gmail, Outlook, etc.)
    let transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: "jr9509171@gmail.com", // Tu correo
            pass: "roas1234"  // Tu contraseña o app password
        }
    });

    let mailOptions = {
        from: "jr9509171@gmail.com",
        to: destinatario,
        subject: asunto,
        text: texto
    };

    // Envía el correo
    await transporter.sendMail(mailOptions);
}

module.exports = { enviarCorreo };