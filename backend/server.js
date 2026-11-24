const express = require('express');
const cors = require('cors');
require('dotenv').config();

const supabase = require('./config/supabase');

const app = express();
const PORT = process.env.PORT || 4000;

// Middlewares
app.use(cors());
app.use(express.json());

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({
        mensaje: 'API del Sistema de Reservas de Restaurante',
        estado: 'Servidor funcionando correctamente'
    });
});

// Prueba de conexion con Supabase
app.get('/api/prueba-conexion', async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('mesas')
            .select('id, numero, capacidad');

        if (error) {
            throw error;
        }

        res.json({
            mensaje: 'Conexion exitosa con Supabase',
            estado: 'Conectado',
            datos: data
        });

    } catch (error) {
        console.error('Error de conexion:', error.message);

        res.status(500).json({
            mensaje: 'Error al conectar con Supabase',
            estado: 'Error'
        });
    }
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Servidor ejecutandose en http://localhost:${PORT}`);
});