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
@endphp

<label @class(['premium-select-field', 'is-disabled' => $disabled]) for="{{ $fieldId }}">
    <span class="premium-select-icon" aria-hidden="true">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{!! $icons[$icon] ?? $icons['filter'] !!}</svg>
    </span>
    <span class="premium-select-main">
        <span class="premium-select-label">{{ $label }}</span>
        @if($hint)
            <span class="premium-select-hint">{{ $hint }}</span>
        @endif
        <span class="premium-select-control">
            <select id="{{ $fieldId }}" name="{{ $name }}" @disabled($disabled)>
                @if($placeholder !== null)
                    <option value="">{{ $placeholder }}</option>
                @endif
                @foreach($options as $option)
                    @php
                        $value = (string) ($option['value'] ?? '');
                        $optionLabel = $option['label'] ?? $value;
                        $meta = $option['meta'] ?? null;
                    @endphp
                    <option value="{{ $value }}" @selected($selectedValue === $value)>
                        {{ $optionLabel }}@if($meta) - {{ $meta }}@endif
                    </option>
                @endforeach
            </select>
            <span class="premium-select-chevron" aria-hidden="true">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m6 9 6 6 6-6"/></svg>
            </span>
        </span>
    </span>
</label>
