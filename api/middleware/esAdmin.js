const esAdmin = (req, res, next) => {
    if (req.user && req.user.admin) {
        next();
    } else {
        res.status(403).json({ 
            success: false,
            error: 'Se requieren privilegios de administrador' 
        });
    }
};

module.exports = esAdmin;