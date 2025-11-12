<template>
  <Tooltip v-if="user && user.full_name" :text="user.full_name">
    <Avatar
      class="avatar border border-outline-gray-2 cursor-auto"
      :label="user.full_name"
      :image="user.user_image"
      :size="size"
      v-bind="$attrs"
    />
  </Tooltip>
  <div
    v-else
    class="avatar border border-outline-gray-2 cursor-auto bg-gray-200 rounded-full flex items-center justify-center"
    :style="`width: ${size || 32}px; height: ${size || 32}px;`"
  >
    <span class="text-xs text-gray-600">?</span>
  </div>
</template>
<script setup>
import { Avatar, Tooltip } from 'frappe-ui'
const props = defineProps({
  user: {
    type: Object,
    default: null,
  },
  size: {
    type: String,
  },
})
</script>
