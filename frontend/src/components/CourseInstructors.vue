<template>
  <div v-if="instructors && instructors.length > 0" class="">
    <span v-if="instructors.length == 1 && instructors[0]">
      <router-link
        v-if="instructors[0].username"
        :to="{
          name: 'Profile',
          params: { username: instructors[0].username },
        }"
      >
        {{
          instructors[0].full_name || instructors[0].first_name || 'Instructor'
        }}
      </router-link>
      <span v-else>
        {{
          instructors[0].full_name || instructors[0].first_name || 'Instructor'
        }}
      </span>
    </span>
    <span v-if="instructors.length == 2 && instructors[0] && instructors[1]">
      <router-link
        v-if="instructors[0].username"
        :to="{
          name: 'Profile',
          params: { username: instructors[0].username },
        }"
      >
        {{
          instructors[0].first_name || instructors[0].full_name || 'Instructor'
        }}
      </router-link>
      <span v-else>
        {{
          instructors[0].first_name || instructors[0].full_name || 'Instructor'
        }}
      </span>
      {{ __('and') }}
      <router-link
        v-if="instructors[1].username"
        :to="{
          name: 'Profile',
          params: { username: instructors[1].username },
        }"
      >
        {{
          instructors[1].first_name || instructors[1].full_name || 'Instructor'
        }}
      </router-link>
      <span v-else>
        {{
          instructors[1].first_name || instructors[1].full_name || 'Instructor'
        }}
      </span>
    </span>
    <span v-if="instructors.length > 2 && instructors[0]">
      <router-link
        v-if="instructors[0].username"
        :to="{
          name: 'Profile',
          params: { username: instructors[0].username },
        }"
      >
        {{
          instructors[0].first_name || instructors[0].full_name || 'Instructor'
        }}
      </router-link>
      <span v-else>
        {{
          instructors[0].first_name || instructors[0].full_name || 'Instructor'
        }}
      </span>
      {{ __('and') }} {{ instructors.length - 1 }} {{ __('others') }}
    </span>
  </div>
</template>
<script setup>
const props = defineProps({
  instructors: {
    type: Array,
    default: () => [],
  },
})
</script>
