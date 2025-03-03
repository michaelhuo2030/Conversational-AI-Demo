import type { Config } from 'tailwindcss'

export default {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['var(--font-inter)'],
        mono: ['var(--font-roboto-mono)'],
      },
      colors: {
        background: 'var(--background)',
        foreground: 'var(--foreground)',
        card: {
          DEFAULT: 'var(--card)',
          foreground: 'var(--card-foreground)',
        },
        popover: {
          DEFAULT: 'var(--popover)',
          foreground: 'var(--popover-foreground)',
        },
        primary: {
          DEFAULT: 'var(--primary)',
          foreground: 'var(--primary-foreground)',
        },
        secondary: {
          DEFAULT: 'var(--secondary)',
          foreground: 'var(--secondary-foreground)',
        },
        muted: {
          DEFAULT: 'var(--muted)',
          foreground: 'var(--muted-foreground)',
        },
        accent: {
          DEFAULT: 'var(--accent)',
          foreground: 'var(--accent-foreground)',
        },
        destructive: {
          DEFAULT: 'var(--destructive)',
          foreground: 'var(--destructive-foreground)',
        },
        border: 'var(--border)',
        input: 'var(--input)',
        ring: 'var(--ring)',
        brand: {
          black: {
            DEFAULT: 'var(--ai_brand_black10)',
            '8': 'var(--ai_brand_black8)',
          },
          light: {
            DEFAULT: 'var(--ai_brand_lightbrand6)',
            '7': 'var(--ai_brand_lightbrand7)',
          },
          main: {
            DEFAULT: 'var(--ai_brand_main6)',
            '3': 'var(--ai_brand_main3)',
            '4': 'var(--ai_brand_main4)',
            '5': 'var(--ai_brand_main5)',
            '7': 'var(--ai_brand_main7)',
            hover: 'var(--ai_mainhover)',
          },
          white: {
            DEFAULT: 'var(--ai_brand_white10)',
            '1': 'var(--ai_brand_white1)',
            '6': 'var(--ai_brand_white6)',
            '8': 'var(--ai_brand_white8)',
          },
          red: {
            DEFAULT: 'var(--ai_red1)',
            '6': 'var(--ai_red6)',
          },
          green: {
            DEFAULT: 'var(--ai_green6)',
          },
        },
        icontext: {
          DEFAULT: 'var(--ai_icontext1)',
          hover: 'var(--ai_icontext2)',
          disabled: 'var(--ai_icontext3)',
          inverse: 'var(--ai_icontext_inverse1)',
        },
        fill: {
          DEFAULT: 'var(--ai_fill1)',
          popover: 'var(--ai_fill2)',
          drawer: 'var(--ai_fill5)',
        },
        block: {
          DEFAULT: 'var(--ai_block1)',
          ['2']: 'var(--ai_block2)',
          ['3']: 'var(--ai_block3)',
          ['4']: 'var(--ai_block4_chat)',
          ['5']: 'var(--ai_block5)',
        },
        line: {
          DEFAULT: 'var(--ai_line1)',
          ['2']: 'var(--ai_line2)',
          ['3']: 'var(--ai_line3)',
        },
      },
      borderRadius: {
        xxxl: 'calc(var(--radius) + 10px)',
        xxl: 'calc(var(--radius) + 6px)',
        xl: 'calc(var(--radius) + 2px)',
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 6px)',
        xs: 'calc(var(--radius) - 8px)',
      },
      animation: {
        rotate: 'rotate 3s linear infinite',
        shake: 'shake 0.2s ease-in-out 2',
      },
      keyframes: {
        rotate: {
          '0%': { transform: 'rotate(0deg) scale(10)' },
          '100%': { transform: 'rotate(-360deg) scale(10)' },
        },
        shake: {
          '0%, 100%': { transform: 'translateX(0)' },
          '25% 75%': { transform: 'translateX(-10px)' },
          '50%': { transform: 'translateX(10px)' },
        },
      },
    },
  },
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  plugins: [require('tailwindcss-animate'), require('@tailwindcss/typography')],
} satisfies Config
