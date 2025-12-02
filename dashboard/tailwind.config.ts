import type { Config } from 'tailwindcss'

const config: Config = {
    content: [
        './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
        './src/components/**/*.{js,ts,jsx,tsx,mdx}',
        './src/app/**/*.{js,ts,jsx,tsx,mdx}',
        './app/**/*.{js,ts,jsx,tsx,mdx}', // Added for app dir at root
        './components/**/*.{js,ts,jsx,tsx,mdx}', // Added for components at root
    ],
    theme: {
        extend: {
            colors: {
                'fraud': '#ef4444',
                'suspicious': '#f59e0b',
                'clean': '#10b981',
            },
        },
    },
    plugins: [],
}
export default config
