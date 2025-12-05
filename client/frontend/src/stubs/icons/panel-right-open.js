import { h } from 'vue'

export default {
  name: 'LucidePanelRightOpen',
  render() {
    return h('span', {
      class: 'icon icon-panel-right-open',
      'aria-hidden': 'true',
      style: { fontSize: '1em', display: 'inline-block', width: '1em', height: '1em' }
    }, '▢')
  }
}