const jwt = require('jsonwebtoken');

exports.handler = async (event) => {
  const { cpf } = JSON.parse(event.body || '{}');
  if (!cpf) {
    return { statusCode: 400, body: JSON.stringify({ message: 'CPF is required' }) };
  }

  // Aqui você integraria com Cognito, AD ou seu banco de clientes.
  // Para mock, vamos simplesmente emitir um JWT contendo o cpf.
  const token = jwt.sign({ cpf }, process.env.JWT_SECRET, { expiresIn: '1h' });
  return {
    statusCode: 200,
    body: JSON.stringify({ token }),
  };
};