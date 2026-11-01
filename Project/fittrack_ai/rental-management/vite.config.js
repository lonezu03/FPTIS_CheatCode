module.exports = async () => ({
  plugins: [(await import('@vitejs/plugin-react')).default()],
  publicDir: false,
  server: {
    host: '127.0.0.1',
    proxy: { '/api': 'http://127.0.0.1:3001' },
  },
});
