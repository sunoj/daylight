const webpack = require("webpack");
const path = require('path');
const postcssNormalize = require('postcss-normalize');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const CopyPlugin = require('copy-webpack-plugin');

function modifyManifest(buffer) {
  let manifest = JSON.parse(buffer.toString());

  // make any modifications you like, such as
  if (process.env.BUILD_VERSION) {
    manifest.version = process.env.BUILD_VERSION;
  }

  // pretty print to JSON with two spaces
  manifest_JSON = JSON.stringify(manifest, null, 2);
  return manifest_JSON;
}


const purgecss = require('@fullhuman/postcss-purgecss')({
  content: [
    'src/**/*.tsx',
  ],
  defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || [],
  whitelistPatterns: [/^u-/, /^uui-/],
  whitelistPatternsChildren: [/^u-/, /^uui-/, /^UUI-/, /^react-calendar/]
})

// common function to get style loaders
const getStyleLoaders = (cssOptions, preProcessor) => {
  const loaders = [
    require.resolve('style-loader'),
    {
      loader: require.resolve('css-loader'),
      options: cssOptions,
    },
    {
      // Options for PostCSS as we reference these options twice
      // Adds vendor prefixing based on your specified browser support in
      // package.json
      loader: require.resolve('postcss-loader'),
      options: {
        // Necessary for external CSS imports to work
        // https://github.com/facebook/create-react-app/issues/2677
        ident: 'postcss',
        plugins: () => [
          require('tailwindcss'),
          require('postcss-flexbugs-fixes'),
          require('postcss-preset-env')({
            autoprefixer: {
              flexbox: 'no-2009',
            },
            stage: 3,
          }),
          ...(process.env.NODE_ENV === 'production' ? [purgecss] : []),
          // Adds PostCSS Normalize as the reset css with default options,
          // so that it honors browserslist config in package.json
          // which in turn let's users customize the target behavior as per their needs.
          postcssNormalize(),
        ],
        sourceMap: this.mode == 'production' && shouldUseSourceMap,
      },
    },
  ].filter(Boolean);
  if (preProcessor) {
    loaders.push(
      {
        loader: require.resolve('resolve-url-loader'),
        options: {
          sourceMap: this.mode == 'production' && shouldUseSourceMap,
        },
      },
      {
        loader: require.resolve(preProcessor),
        options: {
          sourceMap: true,
        },
      }
    );
  }
  return loaders;
};

module.exports = {
  entry: {
    popup: path.join(__dirname, '../src/popup/index.tsx'),
    background: path.join(__dirname, '../src/background.ts'),
  },
  output: {
    path: path.join(__dirname, '../build'),
  },
  optimization: {
    splitChunks: {
      name: 'vendor',
      chunks: "initial"
    }
  },
  module: {
    rules: [
      {
        test: /\.json$/,
        loader: require.resolve('json-loader')
      },
      {
        test: /\.(js|jsx|ts|tsx)$/,
        loader: require.resolve('babel-loader'),
        options: {
          plugins: ["@babel/plugin-proposal-class-properties"],
          presets: ["@babel/preset-env", "@babel/preset-react", "@babel/typescript"],
          babelrc: false,
          configFile: false,
        }
      },
      // Process any JS outside of the app with Babel.
      // Unlike the application JS, we only compile the standard ES features.
      {
        test: /\.(js|mjs)$/,
        exclude: /@babel(?:\/|\\{1,2})runtime/,
        loader: require.resolve('babel-loader'),
      },
      {
        test: /\.css$/,
        use: getStyleLoaders({
          importLoaders: 1,
          sourceMap: false,
        }),
        sideEffects: true,
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.css', '.json']
  },
  plugins: [
    new CopyPlugin([
      {
        from: "public/manifest.json",
        to: "./manifest.json",
        transform(content, path) {
          return modifyManifest(content)
        }
      },
      { from: 'public', to: '.' },
    ]),
    // Generates an `index.html` file with the <script> injected.
    new HtmlWebpackPlugin(
      Object.assign(
        {},
        {
          inject: true,
          chunks: ['popup'],
          template: path.join(__dirname, '../public/index.html'),
        },
        this.mode == 'production'
          ? {
            minify: {
              removeComments: true,
              collapseWhitespace: true,
              removeRedundantAttributes: true,
              useShortDoctype: true,
              removeEmptyAttributes: true,
              removeStyleLinkTypeAttributes: true,
              keepClosingSlash: true,
              minifyJS: true,
              minifyCSS: true,
              minifyURLs: true,
            },
          }
          : undefined
      )
    ),
    new HtmlWebpackPlugin({ inject: 'body', chunks: ['background'], filename: 'background.html' }),
    // exclude locale files in moment
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
    new webpack.EnvironmentPlugin(['NODE_ENV'])
  ]
};
