const { Resend } = require('resend');

const resend = new Resend('re_Uoqafv2M_6rAAJX2MLYARh7u6ywaLxiir');

async function enviarCorreo(destinatario, asunto, texto) {
    await resend.emails.send({
        from: 'apariciorgustavo@gmail.com',
        to: destinatario,
        subject: asunto,
        html: `<p>${texto}</p>`
    });
}
module.exports = { enviarCorreo };