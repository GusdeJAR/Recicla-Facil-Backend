const { Resend } = require('resend');

const resend = new Resend('re_KtfoQvjE_BrYdGJ8YAgznKtV2SiCGExsE');

async function enviarCorreo(destinatario, asunto, texto) {
    await resend.emails.send({
        from: 'onboarding@resend.dev',
        to: destinatario,
        subject: asunto,
        html: `<p>${texto}</p>`
    });
}
module.exports = { enviarCorreo };