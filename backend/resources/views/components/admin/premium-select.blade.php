@props([
    'name',
    'label',
    'options' => [],
    'selected' => null,
    'id' => null,
    'placeholder' => null,
    'disabled' => false,
    'icon' => 'filter',
    'hint' => null,
])

@php
    $fieldId = $id ?? str_replace(['[', ']'], ['_', ''], $name);
    $selectedValue = $selected === null ? '' : (string) $selected;
    $icons = [
        'bike' => '<path d="M5.5 17.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M18.5 17.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z"/><path d="M12 17.5 9 10h4l3 7.5"/><path d="M9 10 6 17.5"/><path d="M13 10l2-4h2"/>',
        'route' => '<path d="M6 19a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M18 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M8.2 14.8 15.8 9.2"/>',
        'status' => '<path d="M4 6h16"/><path d="M7 12h10"/><path d="M10 18h4"/>',
        'filter' => '<path d="M3 5h18"/><path d="M7 12h10"/><path d="M10 19h4"/>',
    ];
    $normalizedOptions = collect();

    if ($placeholder !== null) {
        $normalizedOptions->push([
            'value' => '',
            'label' => $placeholder,
            'title' => $placeholder,
            'meta' => null,
        ]);
    }

    foreach ($options as $option) {
        $value = (string) ($option['value'] ?? '');
        $optionLabel = $option['label'] ?? $value;
        $meta = $option['meta'] ?? null;
        $title = $optionLabel;

        if ($meta === null && str_contains($optionLabel, ' - ')) {
            [$title, $meta] = explode(' - ', $optionLabel, 2);
        }

        $normalizedOptions->push([
            'value' => $value,
            'label' => $optionLabel,
            'title' => $title,
            'meta' => $meta,
        ]);
    }

    $selectedOption = $normalizedOptions->firstWhere('value', $selectedValue) ?? $normalizedOptions->first();
@endphp

<div @class(['premium-select-field', 'is-disabled' => $disabled]) data-premium-select>
    <span class="premium-select-icon" aria-hidden="true">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{!! $icons[$icon] ?? $icons['filter'] !!}</svg>
    </span>
    <span class="premium-select-main">
        <span class="premium-select-label" id="{{ $fieldId }}-label">{{ $label }}</span>
        @if($hint)
            <span class="premium-select-hint">{{ $hint }}</span>
        @endif
        <span class="premium-select-control">
            <select class="premium-select-native" id="{{ $fieldId }}" name="{{ $name }}" @disabled($disabled)>
                @foreach($normalizedOptions as $option)
                    <option value="{{ $option['value'] }}" @selected($selectedValue === $option['value'])>
                        {{ $option['label'] }}@if($option['meta'] && ! str_contains((string) $option['label'], (string) $option['meta'])) - {{ $option['meta'] }}@endif
                    </option>
                @endforeach
            </select>
            <button
                class="premium-select-trigger"
                type="button"
                @disabled($disabled)
                aria-haspopup="listbox"
                aria-expanded="false"
                aria-labelledby="{{ $fieldId }}-label {{ $fieldId }}-value"
            >
                <span class="premium-select-current">
                    <span class="premium-select-current-title" id="{{ $fieldId }}-value">{{ $selectedOption['title'] ?? $placeholder ?? 'Pilih data' }}</span>
                    @if(! empty($selectedOption['meta']))
                        <span class="premium-select-current-meta">{{ $selectedOption['meta'] }}</span>
                    @endif
                </span>
                <span class="premium-select-chevron" aria-hidden="true">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>
                </span>
            </button>
        </span>
    </span>
    <div class="premium-select-menu" role="listbox" aria-labelledby="{{ $fieldId }}-label" hidden>
        @foreach($normalizedOptions as $option)
            <button
                class="premium-select-option"
                type="button"
                role="option"
                data-value="{{ $option['value'] }}"
                data-title="{{ $option['title'] }}"
                data-meta="{{ $option['meta'] }}"
                aria-selected="{{ $selectedValue === $option['value'] ? 'true' : 'false' }}"
            >
                <span class="premium-select-option-check" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="m20 6-11 11-5-5"/></svg>
                </span>
                <span class="premium-select-option-copy">
                    <span class="premium-select-option-title">{{ $option['title'] }}</span>
                    @if($option['meta'])
                        <span class="premium-select-option-meta">{{ $option['meta'] }}</span>
                    @endif
                </span>
            </button>
        @endforeach
    </div>
</div>
