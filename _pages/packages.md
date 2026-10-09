---
permalink: /packages
layout: page
icon: package
window: package-installer
title: Packages
description: "Libraries and tools for Cuis, built by the community."
---

<div id="package-list">
  <div class="package-filters">
    <input class="search" placeholder="Search package">
    <label class="filter"><input type="checkbox" class="featured-filter"><svg class="icon"><use href="{{ "/assets/icons.svg#sparkles" | relative_url }}"></use></svg>Featured</label>
    <label class="filter"><input type="checkbox" class="official-filter"><svg class="icon"><use href="{{ "/assets/icons.svg#badge-check" | relative_url }}"></use></svg>Official</label>
  </div>
  <ul class="list">
    {% for package in site.data.packages %}
    <li{% if package.featured %} class="world" data-featured{% endif %}{% if package.official %} data-official{% endif %} data-topics="{{ package.topics | join: ' ' }}">
      <h4 class="name">{{ package.name }}</h4>
      {% assign source = package.sources.first %}
      <div class="source">
        <a href="{{ source.url }}">{{ source.repo }}</a>{% if source.official %}<span class="official"><svg class="icon"><use href="{{ "/assets/icons.svg#badge-check" | relative_url }}"></use></svg>Official</span>{% endif %}
        {% if source.description %}<p class="description">{{ source.description }}</p>{% endif %}
      </div>
      {% assign more = package.sources.size | minus: 1 %}
      {% assign dialog = "sources-" | append: forloop.index %}
      <div class="package-footer">
        {% if more > 0 %}<button class="more-sources" commandfor="{{ dialog }}" command="show-modal">{{ more }} more {% if more == 1 %}repository{% else %}repositories{% endif %}</button>{% endif %}
        <time datetime="{{ package.pushed_at }}"><svg class="icon"><use href="{{ "/assets/icons.svg#calendar" | relative_url }}"></use></svg>{{ package.pushed_at | date: site.date_format }}</time>
      </div>
      {% if more > 0 %}
      <dialog id="{{ dialog }}" class="sources" closedby="any" aria-labelledby="{{ dialog }}-title">
        <h4 id="{{ dialog }}-title" tabindex="-1" autofocus>{{ package.name }}<button commandfor="{{ dialog }}" command="close" aria-label="Close"><svg class="icon"><use href="{{ "/assets/icons.svg#x" | relative_url }}"></use></svg></button></h4>
        {% for source in package.sources %}
        <div class="source">
          <a href="{{ source.url }}">{{ source.repo }}</a>{% if source.official %}<span class="official"><svg class="icon"><use href="{{ "/assets/icons.svg#badge-check" | relative_url }}"></use></svg>Official</span>{% endif %}
          {% if source.description %}<p class="description">{{ source.description }}</p>{% endif %}
          <p class="pushed"><time datetime="{{ source.pushed_at }}"><svg class="icon"><use href="{{ "/assets/icons.svg#calendar" | relative_url }}"></use></svg>{{ source.pushed_at | date: site.date_format }}</time></p>
        </div>
        {% endfor %}
      </dialog>
      {% endif %}
    </li>
    {% endfor %}
  </ul>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/minisearch/7.2.0/umd/index.min.js"></script>
<script>
const list = document.querySelector('#package-list .list');
const cards = [...list.children];
const search = new MiniSearch({
  fields: ['name', 'topics', 'descriptions'],
  processTerm: term => Array.from(term, (_, i) => term.toLowerCase().slice(i)),
  searchOptions: { processTerm: term => term.toLowerCase(), prefix: true, fuzzy: 0.2, combineWith: 'AND', boost: { name: 2 } }
});
search.addAll(cards.map((card, id) => ({
  id,
  name: card.querySelector('.name').textContent,
  topics: card.dataset.topics,
  descriptions: [...card.querySelectorAll('.description')].map(description => description.textContent).join(' ')
})));

document.querySelector('#package-list .search').addEventListener('input', event => {
  list.replaceChildren(...(event.target.value ? search.search(event.target.value).map(result => cards[result.id]) : cards));
});
</script>
