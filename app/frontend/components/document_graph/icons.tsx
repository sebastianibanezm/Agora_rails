import type { SVGProps } from "react"

type IconProps = SVGProps<SVGSVGElement>

function BaseIcon({ children, ...props }: IconProps & { children: React.ReactNode }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" {...props}>
      {children}
    </svg>
  )
}

export const Icon = {
  contract: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" />
      <path d="M14 3v6h6" />
      <path d="M8 13h6" />
      <path d="M8 17h8" />
    </BaseIcon>
  ),
  po: (props: IconProps) => (
    <BaseIcon {...props}>
      <rect x="3" y="6" width="18" height="13" rx="2" />
      <path d="M3 10h18" />
      <path d="M8 3v4M16 3v4" />
    </BaseIcon>
  ),
  invoice: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M6 3h12v18l-3-2-3 2-3-2-3 2z" />
      <path d="M9 8h6M9 12h6M9 16h4" />
    </BaseIcon>
  ),
  packing: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M3 7l9-4 9 4-9 4z" />
      <path d="M3 7v10l9 4 9-4V7" />
      <path d="M12 11v10" />
    </BaseIcon>
  ),
  bl: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M2 12h6l2-3h4l2 3h6" />
      <path d="M3 12l2 6h14l2-6" />
      <path d="M12 4v5" />
    </BaseIcon>
  ),
  phyto: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 21V8" />
      <path d="M5 8c0-3 3-5 7-5s7 2 7 5c0 3-2 6-7 6s-7-3-7-6z" />
    </BaseIcon>
  ),
  inspection: (props: IconProps) => (
    <BaseIcon {...props}>
      <circle cx="11" cy="11" r="6" />
      <path d="M21 21l-5-5" />
    </BaseIcon>
  ),
  origin: (props: IconProps) => (
    <BaseIcon {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18" />
    </BaseIcon>
  ),
  insurance: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z" />
    </BaseIcon>
  ),
  qc: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M9 12l2 2 4-4" />
      <path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z" />
    </BaseIcon>
  ),
  precool: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 2v20M4.93 4.93l14.14 14.14M19.07 4.93L4.93 19.07M2 12h20" />
    </BaseIcon>
  ),
  customs: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M4 21V9l8-6 8 6v12" />
      <path d="M9 21v-6h6v6" />
    </BaseIcon>
  ),
  permit: (props: IconProps) => (
    <BaseIcon {...props}>
      <rect x="4" y="5" width="16" height="14" rx="2" />
      <path d="M8 9h8M8 13h5" />
      <circle cx="16" cy="14" r="2" />
    </BaseIcon>
  ),
  testlab: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M9 3v6L4 19a2 2 0 0 0 2 3h12a2 2 0 0 0 2-3l-5-10V3" />
      <path d="M9 3h6" />
    </BaseIcon>
  ),
  apple: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 7c-1-2-3-2.5-4.5-2C5 6 3.5 8.5 4 12c.5 4 3 8 5.5 8 1 0 1.7-.5 2.5-.5s1.5.5 2.5.5c2.5 0 5-4 5.5-8 .5-3.5-1-6-3.5-7-1.5-.5-3.5 0-4.5 2z" />
      <path d="M13 3c0 1.5-1 3-3 3" />
    </BaseIcon>
  ),
  user: (props: IconProps) => (
    <BaseIcon {...props}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21c0-4 4-6 8-6s8 2 8 6" />
    </BaseIcon>
  ),
  globe: (props: IconProps) => (
    <BaseIcon {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18" />
      <path d="M12 3a14 14 0 0 1 0 18" />
      <path d="M12 3a14 14 0 0 0 0 18" />
    </BaseIcon>
  ),
  close: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M18 6L6 18M6 6l12 12" />
    </BaseIcon>
  ),
  external: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <path d="M15 3h6v6" />
      <path d="M10 14L21 3" />
    </BaseIcon>
  ),
  download: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <path d="M7 10l5 5 5-5" />
      <path d="M12 15V3" />
    </BaseIcon>
  ),
  link: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M10 14a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-2 2" />
      <path d="M14 10a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l2-2" />
    </BaseIcon>
  ),
  alert: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 9v4M12 17h.01" />
      <path d="M10.3 3.86l-8 14a2 2 0 0 0 1.7 3h16a2 2 0 0 0 1.7-3l-8-14a2 2 0 0 0-3.4 0z" />
    </BaseIcon>
  ),
  chevron: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M9 6l6 6-6 6" />
    </BaseIcon>
  ),
  layout: (props: IconProps) => (
    <BaseIcon {...props}>
      <rect x="4" y="4" width="7" height="7" rx="1" />
      <rect x="13" y="4" width="7" height="7" rx="1" />
      <rect x="4" y="13" width="7" height="7" rx="1" />
      <rect x="13" y="13" width="7" height="7" rx="1" />
    </BaseIcon>
  ),
  container: (props: IconProps) => (
    <BaseIcon {...props}>
      <rect x="3" y="7" width="18" height="11" rx="1.5" />
      <path d="M7 7v11M11 7v11M15 7v11" />
    </BaseIcon>
  ),
  building: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M4 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16" />
      <path d="M16 9h2a2 2 0 0 1 2 2v10" />
      <path d="M8 7h4M8 11h4M8 15h4" />
    </BaseIcon>
  ),
  ship: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M4 17h16l-2 4H6z" />
      <path d="M6 17V9h9l3 8" />
      <path d="M9 9V5h5v4" />
    </BaseIcon>
  ),
  bar: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M4 19V5" />
      <path d="M4 19h18" />
      <rect x="7" y="11" width="3" height="5" rx="1" />
      <rect x="12" y="8" width="3" height="8" rx="1" />
      <rect x="17" y="5" width="3" height="11" rx="1" />
    </BaseIcon>
  ),
  search: (props: IconProps) => (
    <BaseIcon {...props}>
      <circle cx="11" cy="11" r="6" />
      <path d="M20 20l-4.5-4.5" />
    </BaseIcon>
  ),
  filter: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M4 6h16" />
      <path d="M7 12h10" />
      <path d="M10 18h4" />
    </BaseIcon>
  ),
  bell: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 7h18s-3 0-3-7" />
      <path d="M10 20a2 2 0 0 0 4 0" />
    </BaseIcon>
  ),
  plus: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M12 5v14M5 12h14" />
    </BaseIcon>
  ),
  check: (props: IconProps) => (
    <BaseIcon {...props}>
      <path d="M5 12.5l4.2 4.2L19 7" />
    </BaseIcon>
  ),
}

export function DocIcon({ type, ...props }: IconProps & { type?: string }) {
  const Component = Icon[(type || "invoice") as keyof typeof Icon] || Icon.invoice
  return <Component {...props} />
}
