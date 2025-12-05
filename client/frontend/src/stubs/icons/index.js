// Dynamic icon resolver for frappe-ui
// This creates stub components for any ~icons/lucide/* import

import { h } from 'vue'

// Create a stub component for any icon
function createIconComponent(name) {
  return {
    name: `Lucide${name}`,
    render() {
      // Return a simple span with the icon name
      return h('span', {
        class: `icon icon-${name.toLowerCase()}`,
        'aria-hidden': 'true',
        style: { fontSize: '1em', display: 'inline-block', width: '1em', height: '1em' }
      }, '□') // Using a square as placeholder
    }
  }
}

// Export individual icons that are commonly used
export const info = createIconComponent('Info')
export const alertTriangle = createIconComponent('AlertTriangle')
export const x = createIconComponent('X')
export const chevronDown = createIconComponent('ChevronDown')
export const chevronRight = createIconComponent('ChevronRight')
export const panelRightOpen = createIconComponent('PanelRightOpen')
export const check = createIconComponent('Check')
export const plus = createIconComponent('Plus')
export const search = createIconComponent('Search')
export const settings = createIconComponent('Settings')
export const eye = createIconComponent('Eye')
export const eyeOff = createIconComponent('EyeOff')
export const copy = createIconComponent('Copy')
export const pencil = createIconComponent('Pencil')
export const link2Off = createIconComponent('Link2Off')
export const download = createIconComponent('Download')
export const maximize = createIconComponent('Maximize')
export const minimize = createIconComponent('Minimize')
export const chevronLeft = createIconComponent('ChevronLeft')
export const chevronRight = createIconComponent('ChevronRight')
export const minus = createIconComponent('Minus')
export const moveDiagonal2 = createIconComponent('MoveDiagonal2')
export const alignLeft = createIconComponent('AlignLeft')
export const alignCenter = createIconComponent('AlignCenter')
export const alignRight = createIconComponent('AlignRight')
export const edit = createIconComponent('Edit')
export const imagePlus = createIconComponent('ImagePlus')
export const command = createIconComponent('Command')
export const arrowBigUp = createIconComponent('ArrowBigUp')
export const option = createIconComponent('Option')
export const arrowUp = createIconComponent('ArrowUp')
export const arrowDown = createIconComponent('ArrowDown')
export const arrowLeft = createIconComponent('ArrowLeft')
export const arrowRight = createIconComponent('ArrowRight')
export const cornerDownLeft = createIconComponent('CornerDownLeft')
export const deleteIcon = createIconComponent('Delete')
export const bell = createIconComponent('Bell')
export const briefcase = createIconComponent('Briefcase')
export const building = createIconComponent('Building')
export const checkSquare = createIconComponent('CheckSquare')
export const clipboard = createIconComponent('Clipboard')
export const link = createIconComponent('Link')
export const mail = createIconComponent('Mail')
export const moon = createIconComponent('Moon')
export const phone = createIconComponent('Phone')
export const user = createIconComponent('User')
export const userCheck = createIconComponent('UserCheck')
export const users = createIconComponent('Users')

// For dynamic imports, use a proxy
const iconProxy = new Proxy({}, {
  get(target, prop) {
    if (typeof prop === 'string') {
      return createIconComponent(prop)
    }
    return createIconComponent('Icon')
  }
})

export default iconProxy