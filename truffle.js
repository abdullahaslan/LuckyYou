module.exports = {
  networks: {
    rinkeby: {
      network_id: 4,
      host: '127.0.0.1',
      port: 8545,
      gas: 4000000,
      from: 0xb12B7CCe664F7F02d9f0F5A53A4B977e5279d15D
    },
  },
  rpc: {
    // Use the default host and port when not using rinkeby
    host: 'localhost',
    port: 8080,
  },
};