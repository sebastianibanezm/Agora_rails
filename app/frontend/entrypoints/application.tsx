import { createInertiaApp } from '@inertiajs/react'
import { createRoot } from 'react-dom/client'
import './application.css'

const hasInertiaPage = !!document.querySelector('script[data-page="app"][type="application/json"]')

if (hasInertiaPage) {
  createInertiaApp({
    resolve: (name) => {
      const pages = import.meta.glob('../pages/**/*.tsx', { eager: true })
      return pages[`../pages/${name}.tsx`] as any
    },
    setup({ el, App, props }) {
      createRoot(el).render(<App {...props} />)
    },
  })
}
