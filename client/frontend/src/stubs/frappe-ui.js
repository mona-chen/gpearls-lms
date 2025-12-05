// Comprehensive frappe-ui stub for Rails compatibility
// This provides empty implementations for all frappe-ui exports

// Core functions
export function createResource() {
  return {
    data: null,
    loading: false,
    error: null,
    promise: Promise.resolve(),
    fetched: false,
    fetch: () => Promise.resolve(),
    reload: () => Promise.resolve(),
    submit: () => Promise.resolve(),
    reset: () => {},
    update: () => {},
    setData: () => {}
  }
}

export function createListResource() {
  return createResource()
}

export function createDocumentResource() {
  return createResource()
}

export function call() {
  return Promise.resolve({ message: 'Mock response' })
}

export function frappeRequest() {
  return Promise.resolve({ message: 'Mock response' })
}

export function toast() {
  console.log('Toast')
}

export function usePageMeta() {
  return {
    title: '',
    description: '',
    setTitle: () => {},
    setDescription: () => {}
  }
}

export function initSocket() {
  return {
    on: () => {},
    emit: () => {},
    disconnect: () => {}
  }
}

export function setConfig() {}
export function getConfig() { return null }

// Vue components (empty implementations)
import { h } from 'vue'

function createStubComponent(name) {
  return {
    name,
    render() {
      return h('div', { class: name.toLowerCase() }, this.$slots.default?.())
    }
  }
}

export const Button = createStubComponent('Button')
export const Dialog = createStubComponent('Dialog')
export const FormControl = createStubComponent('FormControl')
export const Avatar = createStubComponent('Avatar')
export const Breadcrumbs = createStubComponent('Breadcrumbs')
export const Calendar = createStubComponent('Calendar')
export const Card = createStubComponent('Card')
export const Checkbox = createStubComponent('Checkbox')
export const Combobox = createStubComponent('Combobox')
export const DatePicker = createStubComponent('DatePicker')
export const Dropdown = createStubComponent('Dropdown')
export const ErrorMessage = createStubComponent('ErrorMessage')
export const FileUploader = createStubComponent('FileUploader')
export const Link = createStubComponent('Link')
export const Popover = createStubComponent('Popover')
export const Progress = createStubComponent('Progress')
export const Radio = createStubComponent('Radio')
export const Switch = createStubComponent('Switch')
export const TabButtons = createStubComponent('TabButtons')
export const Tabs = createStubComponent('Tabs')
export const Textarea = createStubComponent('Textarea')
// TextEditor is defined below as special component
export const TextInput = createStubComponent('TextInput')
export const Tooltip = createStubComponent('Tooltip')
export const Badge = createStubComponent('Badge')
export const Input = createStubComponent('Input')
export const ListItem = createStubComponent('ListItem')
export const LoadingIndicator = createStubComponent('LoadingIndicator')
export const LoadingText = createStubComponent('LoadingText')
export const Spinner = createStubComponent('Spinner')
export const Select = createStubComponent('Select')
export const Password = createStubComponent('Password')
export const Rating = createStubComponent('Rating')
export const Resource = createStubComponent('Resource')
export const Sidebar = createStubComponent('Sidebar')
export const FrappeUIProvider = createStubComponent('FrappeUIProvider')
export const CommandPalette = createStubComponent('CommandPalette')
export const ListFilter = createStubComponent('ListFilter')
export const KeyboardShortcut = createStubComponent('KeyboardShortcut')
export const CalendarComponent = createStubComponent('CalendarComponent')
export const CircularProgressBar = createStubComponent('CircularProgressBar')
export const Tree = createStubComponent('Tree')
export const GridLayout = createStubComponent('GridLayout')
export const AxisChart = createStubComponent('AxisChart')
export const NumberChart = createStubComponent('NumberChart')
export const DonutChart = createStubComponent('DonutChart')
export const FunnelChart = createStubComponent('FunnelChart')
export const ECharts = createStubComponent('ECharts')
export const ListView = createStubComponent('ListView')
export const List = createStubComponent('List')
export const ListHeader = createStubComponent('ListHeader')
export const ListHeaderItem = createStubComponent('ListHeaderItem')
export const ListEmptyState = createStubComponent('ListEmptyState')
export const ListRows = createStubComponent('ListRows')
export const ListRow = createStubComponent('ListRow')
export const ListRowItem = createStubComponent('ListRowItem')
export const ListGroups = createStubComponent('ListGroups')
export const ListGroupHeader = createStubComponent('ListGroupHeader')
export const ListGroupRows = createStubComponent('ListGroupRows')
export const ListSelectBanner = createStubComponent('ListSelectBanner')
export const ListFooter = createStubComponent('ListFooter')
export const Toast = createStubComponent('Toast')
export const Dialogs = createStubComponent('Dialogs')
export const FormLabel = createStubComponent('FormLabel')
export const GreenCheckIcon = createStubComponent('GreenCheckIcon')
export const FeatherIcon = createStubComponent('FeatherIcon')
export const Divider = createStubComponent('Divider')
export const TimePicker = createStubComponent('TimePicker')
export const NestedPopover = createStubComponent('NestedPopover')
export const CommandPaletteItem = createStubComponent('CommandPaletteItem')
export const ProgressBar = createStubComponent('ProgressBar')
export const TabList = createStubComponent('TabList')
export const TabPanel = createStubComponent('TabPanel')
export const DateTimePicker = createStubComponent('DateTimePicker')
export const DateRangePicker = createStubComponent('DateRangePicker')

// Special components with more complex implementations
export const TextEditor = {
  name: 'TextEditor',
  props: ['modelValue', 'placeholder'],
  emits: ['update:modelValue'],
  template: '<textarea :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" :placeholder="placeholder"></textarea>'
}

export const ConfirmDialog = {
  name: 'ConfirmDialog',
  render() {
    return h('div', { class: 'confirm-dialog' }, this.$slots.default?.())
  }
}

// Utilities
export const debounce = (func, wait) => func
export const fileToBase64 = () => Promise.resolve('')
export const FileUploadHandler = class {}
export const useFileUpload = () => ({ upload: () => Promise.resolve() })
export const theme = {}
export const resourcesPlugin = { install: () => {} }
export const pageMetaPlugin = { install: () => {} }
export const dayjsLocal = () => {}
export const dayjs = () => {}

// Default export
export default {
  install(app) {
    // Register all components
    const components = [
      Button, Dialog, FormControl, Avatar, Breadcrumbs, Calendar, Card,
      Checkbox, Combobox, DatePicker, Dropdown, ErrorMessage, FileUploader,
      Link, Popover, Progress, Radio, Switch, TabButtons, Tabs, Textarea,
      TextEditor, TextInput, Tooltip, Badge, Input, ListItem, LoadingIndicator,
      LoadingText, Spinner, Select, Password, Rating, Resource, Sidebar,
      FrappeUIProvider, CommandPalette, ListFilter, KeyboardShortcut,
      CalendarComponent, CircularProgressBar, Tree, GridLayout, AxisChart,
      NumberChart, DonutChart, FunnelChart, ECharts, ListView, List, ListHeader,
      ListHeaderItem, ListEmptyState, ListRows, ListRow, ListRowItem, ListGroups,
      ListGroupHeader, ListGroupRows, ListSelectBanner, ListFooter, Toast,
      Dialogs, FormLabel, GreenCheckIcon, FeatherIcon, Divider, TimePicker,
      NestedPopover, CommandPaletteItem, ProgressBar, TabList, TabPanel,
      DateTimePicker, DateRangePicker, ConfirmDialog
    ]

    components.forEach(component => {
      if (component.name) {
        app.component(component.name, component)
      }
    })
  }
}