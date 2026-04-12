<template>
  <div class="content-blocks">
    <template v-for="(block, index) in blocks" :key="index">
      <!-- Reference Entry (dictionary-style entry) -->
      <ReferenceEntry v-if="block.type === 'reference_entry'" :block="block" />
      <p v-if="block.type === 'paragraph'" class="mb-3 text-gray-800 dark:text-gray-200 leading-relaxed">
        <template v-if="block.children && block.children.length > 0">
          <template v-for="(child, ci) in block.children" :key="ci">
            <strong v-if="child.type === 'strong'" class="font-bold dark:text-white">{{ child.text }}</strong>
            <em v-else-if="child.type === 'italic'" class="italic dark:text-gray-300">{{ child.text }}</em>
            <em v-else-if="child.type === 'emphasis'" class="italic dark:text-gray-300">{{ child.text }}</em>
            <code v-else-if="child.type === 'codetext'" class="bg-gray-100 dark:bg-gray-800 text-pink-600 dark:text-pink-400 px-1.5 py-0.5 rounded text-sm font-mono border border-gray-200 dark:border-gray-700">{{ child.text }}</code>
            <a v-else-if="child.type === 'link'" :href="child.src" class="text-blue-600 dark:text-blue-400 hover:underline">{{ child.text }}</a>
            <a v-else-if="child.type === 'biblioref'" :href="child.src" class="text-emerald-600 dark:text-emerald-400 hover:underline italic">{{ child.text }}</a>
            <span v-else-if="child.type === 'citation'" class="text-teal-600 dark:text-teal-400 italic">{{ child.text }}</span>
            <a v-else-if="child.type === 'citation_link'" :href="child.src" class="text-teal-600 dark:text-teal-400 hover:underline italic">{{ child.text }}</a>
            <a v-else-if="child.type === 'xref'" :href="child.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400 dark:border-blue-500">{{ child.text }}</a>
            <img v-else-if="child.type === 'inline_image'" :src="child.src" :alt="child.alt || ''" class="max-w-full h-auto rounded inline">
            <span v-else-if="child.type === 'text'" v-html="escapeHtml(child.text || '')"></span>
          </template>
        </template>
        <template v-else>
          <span v-html="escapeHtml(block.text || '')"></span>
        </template>
      </p>

      <!-- Code block -->
      <pre v-else-if="block.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :class="block.language ? 'language-' + block.language : ''"><code :class="block.language ? 'language-' + block.language : ''" v-html="highlightCode(block.text || '', block.language)"></code></pre>

      <!-- Image -->
      <figure v-else-if="block.type === 'image'" class="my-6 overflow-hidden rounded-lg">
        <img :src="block.src" :alt="block.alt || ''" class="max-w-full h-auto rounded shadow" loading="lazy">
        <figcaption v-if="block.title" class="mt-2 text-sm text-gray-600 dark:text-gray-400 text-center italic">{{ block.title }}</figcaption>
      </figure>

      <!-- Blockquote -->
      <blockquote v-else-if="block.type === 'blockquote'" class="border-l-4 border-blue-500 pl-4 py-1 my-4 bg-gray-50 dark:bg-gray-800/50 rounded-r-lg">
        <p v-for="(child, ci) in block.children" :key="ci" class="mb-3 text-gray-800 dark:text-gray-200">
          <template v-if="child.type === 'paragraph'">{{ child.text }}</template>
        </p>
        <footer v-if="block.text" class="text-gray-500 dark:text-gray-400 text-sm mt-2">&mdash; {{ block.text }}</footer>
      </blockquote>

      <!-- Ordered List -->
      <ol v-else-if="block.type === 'ordered_list'" class="list-decimal ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.children" :key="li" class="text-gray-800 dark:text-gray-200">
          <template v-if="item.type === 'list_item'">
            <template v-for="(child, ci) in item.children" :key="ci">
              <p v-if="child.type === 'paragraph'" class="mb-3">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="bg-gray-100 dark:bg-gray-800 text-pink-600 dark:text-pink-400 px-1.5 py-0.5 rounded text-sm font-mono border border-gray-200 dark:border-gray-700">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400 dark:border-blue-500">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </p>
            </template>
          </template>
        </li>
      </ol>

      <!-- Itemized List -->
      <ul v-else-if="block.type === 'itemized_list'" class="list-disc ml-6 mb-3 space-y-1">
        <li v-for="(item, li) in block.children" :key="li" class="text-gray-800 dark:text-gray-200">
          <template v-if="item.type === 'list_item'">
            <template v-for="(child, ci) in item.children" :key="ci">
              <p v-if="child.type === 'paragraph'" class="mb-3">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="bg-gray-100 dark:bg-gray-800 text-pink-600 dark:text-pink-400 px-1.5 py-0.5 rounded text-sm font-mono border border-gray-200 dark:border-gray-700">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400 dark:border-blue-500">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </p>
            </template>
          </template>
        </li>
      </ul>

      <!-- Definition List (glossary) -->
      <dl v-else-if="block.type === 'definition_list'" class="mb-4 ml-4">
        <template v-for="(item, di) in block.children" :key="di">
          <template v-if="item.type === 'definition_term'">
            <template v-for="(child, ci) in (item.children || [])" :key="ci">
              <dt v-if="child.type === 'text'" class="font-semibold text-gray-800 dark:text-gray-200 mt-2">{{ child.text }}</dt>
              <dt v-else-if="child.type === 'codetext'" class="font-mono text-pink-600 dark:text-pink-400 mt-2">{{ child.text }}</dt>
            </template>
          </template>
          <template v-if="item.type === 'definition_description'">
            <template v-for="(child, ci) in (item.children || [])" :key="ci">
              <dd v-if="child.type === 'paragraph'" class="ml-4 text-gray-700 dark:text-gray-300 mb-2">
                <template v-for="(para, pi) in (child.children || [])" :key="pi">
                  <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
                  <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
                  <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
                  <code v-else-if="para.type === 'codetext'" class="bg-gray-100 dark:bg-gray-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
                  <a v-else-if="para.type === 'link'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline">{{ para.text }}</a>
                  <a v-else-if="para.type === 'biblioref'" :href="para.src" class="text-emerald-600 dark:text-emerald-400 hover:underline italic">{{ para.text }}</a>
                  <span v-else-if="para.type === 'citation'" class="text-teal-600 dark:text-teal-400 italic">{{ para.text }}</span>
                  <a v-else-if="para.type === 'citation_link'" :href="para.src" class="text-teal-600 dark:text-teal-400 hover:underline italic">{{ para.text }}</a>
                  <a v-else-if="para.type === 'xref'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400 dark:border-blue-500">{{ para.text }}</a>
                  <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
                  <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
                </template>
              </dd>
            </template>
          </template>
        </template>
      </dl>

      <!-- Admonitions -->
      <div v-else-if="block.type === 'note'" class="border-l-4 border-blue-500 rounded-r-lg p-4 my-4 bg-blue-50 dark:bg-blue-900/20">
        <div class="font-bold text-blue-700 dark:text-blue-300 mb-1">{{ block.text || 'Note' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-blue-700 dark:text-blue-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-blue-100 dark:bg-blue-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'warning'" class="border-l-4 border-yellow-500 rounded-r-lg p-4 my-4 bg-yellow-50 dark:bg-yellow-900/20">
        <div class="font-bold text-yellow-700 dark:text-yellow-300 mb-1">{{ block.text || 'Warning' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-yellow-700 dark:text-yellow-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-yellow-100 dark:bg-yellow-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-yellow-600 dark:text-yellow-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-yellow-600 dark:text-yellow-400 hover:underline border-b border-dashed border-yellow-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'danger'" class="border-l-4 border-red-500 rounded-r-lg p-4 my-4 bg-red-50 dark:bg-red-900/20">
        <div class="font-bold text-red-700 dark:text-red-300 mb-1">{{ block.text || 'Danger' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-red-700 dark:text-red-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-red-100 dark:bg-red-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-red-600 dark:text-red-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-red-600 dark:text-red-400 hover:underline border-b border-dashed border-red-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'caution'" class="border-l-4 border-orange-500 rounded-r-lg p-4 my-4 bg-orange-50 dark:bg-orange-900/20">
        <div class="font-bold text-orange-700 dark:text-orange-300 mb-1">{{ block.text || 'Caution' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-orange-700 dark:text-orange-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-orange-100 dark:bg-orange-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-orange-600 dark:text-orange-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-orange-600 dark:text-orange-400 hover:underline border-b border-dashed border-orange-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'important'" class="border-l-4 border-purple-500 rounded-r-lg p-4 my-4 bg-purple-50 dark:bg-purple-900/20">
        <div class="font-bold text-purple-700 dark:text-purple-300 mb-1">{{ block.text || 'Important' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-purple-700 dark:text-purple-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-purple-100 dark:bg-purple-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-purple-600 dark:text-purple-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-purple-600 dark:text-purple-400 hover:underline border-b border-dashed border-purple-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <div v-else-if="block.type === 'tip'" class="border-l-4 border-green-500 rounded-r-lg p-4 my-4 bg-green-50 dark:bg-green-900/20">
        <div class="font-bold text-green-700 dark:text-green-300 mb-1">{{ block.text || 'Tip' }}</div>
        <div v-for="(child, ci) in block.children" :key="ci">
          <p v-if="child.type === 'paragraph'" class="text-green-700 dark:text-green-300 mb-2">
            <template v-for="(para, pi) in (child.children || [])" :key="pi">
              <strong v-if="para.type === 'strong'" class="font-bold">{{ para.text }}</strong>
              <em v-else-if="para.type === 'italic'" class="italic">{{ para.text }}</em>
              <em v-else-if="para.type === 'emphasis'" class="italic">{{ para.text }}</em>
              <code v-else-if="para.type === 'codetext'" class="bg-green-100 dark:bg-green-800 text-pink-600 dark:text-pink-400 px-1 py-0.5 rounded text-sm font-mono">{{ para.text }}</code>
              <a v-else-if="para.type === 'link'" :href="para.src" class="text-green-600 dark:text-green-400 hover:underline">{{ para.text }}</a>
              <a v-else-if="para.type === 'xref'" :href="para.src" class="text-green-600 dark:text-green-400 hover:underline border-b border-dashed border-green-400">{{ para.text }}</a>
              <img v-else-if="para.type === 'inline_image'" :src="para.src" :alt="para.alt || ''" class="max-w-full h-auto rounded inline">
              <span v-else-if="para.type === 'text'" v-html="escapeHtml(para.text || '')"></span>
            </template>
          </p>
          <pre v-else-if="child.type === 'code'" class="bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mb-4 overflow-x-auto text-sm font-mono dark:text-gray-100" :data-language="child.language"><code>{{ child.text }}</code></pre>
        </div>
      </div>

      <!-- Bibliography entry (reference) -->
      <div v-else-if="block.type === 'bibliography_entry'" class="mb-4 ml-4 pl-4 border-l-2 border-gray-300 dark:border-gray-600">
        <p class="text-gray-800 dark:text-gray-200">
          <template v-for="(child, ci) in (block.children || [])" :key="ci">
            <span v-if="child.type === 'text'">{{ child.text }}</span>
            <span v-else-if="child.type === 'biblio_abbrev'" :class="child.className">{{ child.text }}</span>
            <cite v-else-if="child.type === 'biblio_citetitle'" :class="child.className">{{ child.text }}</cite>
            <span v-else-if="child.type === 'biblio_author' || child.type === 'biblio_personname' || child.type === 'biblio_firstname' || child.type === 'biblio_surname'" :class="child.className">{{ child.text }}</span>
            <span v-else-if="child.type === 'biblio_orgname' || child.type === 'biblio_publishername' || child.type === 'biblio_pubdate' || child.type === 'biblio_bibliosource'" :class="child.className">{{ child.text }}</span>
            <a v-else-if="child.type === 'link'" :href="child.src" :class="child.className" class="text-blue-600 dark:text-blue-400 hover:underline">{{ child.text }}</a>
            <a v-else-if="child.type === 'xref'" :href="child.src" class="text-blue-600 dark:text-blue-400 hover:underline border-b border-dashed border-blue-400 dark:border-blue-500">{{ child.text }}</a>
            <span v-if="ci < (block.children?.length || 0) - 1" :key="'space-' + ci"> </span>
          </template>
        </p>
      </div>

      <!-- Reference entry (refentry - dictionary-style entry) -->
      <!-- Handled by ReferenceEntry component above -->

      <!-- Description section (from refsection content) -->
      <div v-else-if="block.type === 'description_section'" class="description-section mb-4">
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Example output (informalexample - styled differently from code) -->
      <div v-else-if="block.type === 'example_output'" class="reference-example bg-green-50 dark:bg-green-900/20 border-2 border-dashed border-green-500 dark:border-green-600 rounded-lg p-4 my-4">
        <span class="reference-example-label text-xs font-semibold uppercase tracking-wide text-green-700 dark:text-green-400 block mb-2">Example:</span>
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Index section (whole index) -->
      <div v-else-if="block.type === 'index_section'" class="mb-8">
        <h2 v-if="block.text" class="text-2xl font-bold mb-6 text-gray-900 dark:text-gray-100">{{ block.text }}</h2>
        <div class="index-columns">
          <BlockRenderer :blocks="block.children || []" />
        </div>
      </div>

      <!-- Index letter group -->
      <div v-else-if="block.type === 'index_letter'" class="index-letter-section mb-6">
        <h3 class="index-letter text-xl font-bold mb-3 text-gray-700 dark:text-gray-300 border-b border-gray-300 dark:border-gray-600 pb-1">{{ block.text }}</h3>
        <ul class="index-entries space-y-1">
          <BlockRenderer :blocks="block.children || []" />
        </ul>
      </div>

      <!-- Index entry -->
      <li v-else-if="block.type === 'index_entry'" class="index-entry ml-4">
        <span class="text-gray-800 dark:text-gray-200">{{ block.text }}</span>
        <template v-for="(child, ci) in block.children" :key="ci">
          <a v-if="child.type === 'index_reference'" :href="child.src" class="index-section-link ml-2 text-blue-600 dark:text-blue-400 hover:underline text-sm">{{ child.text }}</a>
          <span v-else-if="child.type === 'index_see'" class="index-see ml-2 text-gray-500 dark:text-gray-400 italic text-sm">{{ child.text }}</span>
          <span v-else-if="child.type === 'index_see_also'" class="index-see-also ml-2 text-gray-500 dark:text-gray-400 italic text-sm">{{ child.text }}</span>
        </template>
      </li>

      <!-- Nested section blocks -->
      <div v-else-if="block.type === 'section'" class="mb-6">
        <BlockRenderer :blocks="block.children || []" />
      </div>

      <!-- Heading (used for simplesect titles within content) -->
      <h3 v-else-if="block.type === 'heading'" class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2 mt-4">
        {{ block.text }}
      </h3>

      <!-- Reference meta (refentrytitle, refmiscinfo - metadata) -->
      <span v-else-if="block.type === 'reference_meta'" class="reference-meta text-xs text-gray-400 dark:text-gray-500 block mb-1">
        {{ block.text }}
      </span>

      <!-- Reference class (refclass badge) -->
      <span v-else-if="block.type === 'reference_class'" class="reference-badge inline-block px-2 py-0.5 text-xs rounded-full bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300">
        {{ block.text }}
      </span>

      <!-- Reference badge (new type for refclass - e.g., "pi") -->
      <span v-else-if="block.type === 'reference_badge'" class="reference-badge inline-block text-[0.65rem] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
        {{ block.text }}
      </span>

      <!-- Reference name (refname - headword) -->
      <h2 v-else-if="block.type === 'reference_name'" class="reference-name text-2xl font-bold font-mono text-cyan-700 dark:text-cyan-400 mb-1">
        {{ block.text }}
      </h2>

      <!-- Reference definition (refpurpose - definition) -->
      <p v-else-if="block.type === 'reference_definition'" class="reference-definition text-base text-gray-600 dark:text-gray-400 italic mb-4">
        {{ block.text }}
      </p>

      <!-- Fallback: render as paragraph if text exists -->
      <p v-else-if="block.text" class="mb-3 text-gray-800 dark:text-gray-200" v-html="escapeHtml(block.text)"></p>
    </template>
  </div>
</template>

<script setup lang="ts">
import type { ContentBlock } from '../stores/documentStore'
import ReferenceEntry from './ReferenceEntry.vue'

declare const Prism: any

defineProps<{
  blocks: ContentBlock[]
}>()

function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

function highlightCode(text: string, language: string | null): string {
  const lang = language || 'plaintext'
  try {
    if (Prism && Prism.languages && Prism.languages[lang]) {
      return Prism.highlight(text, Prism.languages[lang], lang)
    }
  } catch (e) {
    // Fallback to escaped HTML if Prism fails
  }
  return escapeHtml(text)
}
</script>
