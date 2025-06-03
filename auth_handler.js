// auth_handler.js
const jwt = require('jsonwebtoken');
const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  const { cpf } = JSON.parse(event.body || '{}');
  if (!cpf) {
    return { statusCode: 400, body: JSON.stringify({ message: 'CPF is required' }) };
  }

  // Consulta DynamoDB pela chave 'cpf'
  let customer;
  try {
    const result = await ddb
      .get({
        TableName: process.env.CUSTOMERS_TABLE,
        Key: { cpf },
      })
      .promise();
    customer = result.Item;
  } catch (err) {
    console.error('DynamoDB error', err);
    return { statusCode: 500, body: JSON.stringify({ message: 'Internal server error' }) };
  }

  if (!customer) {
    return { statusCode: 404, body: JSON.stringify({ message: 'Customer not found' }) };
  }

  // Gera JWT com sub = customer.id (ou cpf) e expira em 1h
  const token = jwt.sign(
    { sub: customer.id || cpf, cpf },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );

  return {
    statusCode: 200,
    body: JSON.stringify({ token }),
  };
};
