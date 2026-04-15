/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{vue,ts,html}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        cream: '#faf8f5',
        charcoal: '#2d2d2d',
        gold: '#b8860b',
        burgundy: '#722f37'
      }
    }
  },
  plugins: [],
}
