module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        useBuiltIns: 'usage',
        corejs: 3,
      },
    ],
  ],
  env: {
    debug: {
      sourceMap: 'inline',
      retainLines: true,
    },
  },
}
