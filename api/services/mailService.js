
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const REMITENTE_VERIFICADO = 'reciclafacil471@gmail.com'; 

async function enviarCorreo(destinatario, asunto, texto) {
    

    const msg = {
        to: destinatario,
    
        from: {
            email: REMITENTE_VERIFICADO, 
            name: 'ReciclaFacil'
        }, 
        subject: asunto,
        html: `<p>${texto}</p>`,
    };

    try {
        await sgMail.send(msg);
        console.log(`Correo enviado a: ${destinatario}`);
    } catch (error) {
        // En caso de error, imprime los detalles para depuración.
        console.error('Error al enviar correo con SendGrid:', error.response.body);
        throw new Error('Fallo al enviar el correo.');
    }
}

module.exports = { enviarCorreo };