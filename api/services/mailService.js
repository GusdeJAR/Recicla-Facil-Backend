const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

async function enviarCorreo(destinatario, asunto, texto) {
    await resend.emails.send({
        from: 'ReciclaFacil <onboarding@resend.dev>',
        to: destinatario,
        subject: asunto,
        html: `<p>${texto}</p>`
    });
}
module.exports = { enviarCorreo };