<?php
/**
 * Plugin Name: Green Spots – ACF Revisions
 * Description: Erzwingt WordPress-Revisionen bei ACF-Feldänderungen und zeigt ACF-Felder im Revisionsvergleich an.
 *
 * Problem: wp_save_post_revision() wird aufgerufen BEVOR ACF die neuen Werte via REST speichert.
 * Lösung:  Nach dem ACF-Save (rest_after_insert / acf/save_post) erneut wp_save_post_revision()
 *          aufrufen und danach die neuste Revision mit den aktuellen ACF-Werten synchronisieren.
 */

defined('ABSPATH') || exit;

const GS_ACF_FIELDS = [
    'lat'          => 'Breitengrad',
    'long'         => 'Längengrad',
    'secure'       => 'Sicherheit',
    'space'        => 'Platz',
    'swim'         => 'Baden möglich',
    'fire'         => 'Feuer erlaubt',
    'waterquality' => 'Wasserqualität',
    'note'         => 'Notiz',
    'lastvisited'  => 'Zuletzt besucht',
    'specials'     => 'Besonderheiten',
    'image'        => 'Bild 1 (ID)',
    'image2'       => 'Bild 2 (ID)',
    'image3'       => 'Bild 3 (ID)',
];

// ---------------------------------------------------------------------------
// 1. Revisionsvergleich: ACF-Felder einblenden
// ---------------------------------------------------------------------------

add_filter('_wp_post_revision_fields', function (array $fields): array {
    foreach (GS_ACF_FIELDS as $key => $label) {
        $fields[$key] = $label;
    }
    return $fields;
});

foreach (array_keys(GS_ACF_FIELDS) as $field_key) {
    add_filter("_wp_post_revision_field_{$field_key}", function ($value, string $field, WP_Post $post) {
        $raw = get_post_meta($post->ID, $field, true);
        if (is_array($raw)) {
            return implode(', ', $raw);
        }
        return ($raw !== '' && $raw !== false) ? (string) $raw : '—';
    }, 10, 3);
}

// ---------------------------------------------------------------------------
// 2. Revision erzwingen wenn ACF-Felder sich geändert haben
//    (wird sowohl vom normalen WP-Flow als auch von unserem manuellen
//     wp_save_post_revision()-Aufruf weiter unten genutzt)
// ---------------------------------------------------------------------------

add_filter('wp_save_post_revision_post_has_changed', function (bool $changed, WP_Post $last_revision, WP_Post $post): bool {
    if ($changed || $post->post_type !== 'spot') {
        return $changed;
    }
    foreach (array_keys(GS_ACF_FIELDS) as $field_key) {
        $current  = get_post_meta($post->ID, $field_key, true);
        $previous = get_post_meta($last_revision->ID, $field_key, true);
        if ($current !== $previous) {
            return true;
        }
    }
    return false;
}, 10, 3);

// ---------------------------------------------------------------------------
// 3. ACF-Werte in die neuste Revision schreiben
//    (nach dem ACF-Save, damit die Revision den aktuellen Stand zeigt)
// ---------------------------------------------------------------------------

function gs_sync_acf_to_latest_revision($post_id) {
    if (get_post_type($post_id) !== 'spot') {
        return;
    }
    $revisions = wp_get_post_revisions($post_id, ['limit' => 1, 'order' => 'DESC']);
    if (empty($revisions)) {
        return;
    }
    $revision = reset($revisions);
    foreach (array_keys(GS_ACF_FIELDS) as $field_key) {
        $value = get_post_meta($post_id, $field_key, true);
        delete_metadata('post', $revision->ID, $field_key);
        if ($value !== '' && $value !== false) {
            update_metadata('post', $revision->ID, $field_key, $value);
        }
    }
}

// ---------------------------------------------------------------------------
// 4a. REST API: Nach dem ACF-Save (priority 10) erneut Revision versuchen
//     und dann ACF-Werte in die Revision synchronisieren (priority 20)
// ---------------------------------------------------------------------------

add_action('rest_after_insert_spot', function (WP_Post $post) {
    // ACF hat jetzt gespeichert → Revision erstellen falls ACF sich geändert hat
    wp_save_post_revision($post->ID);
    // Neuste Revision mit den gerade gespeicherten ACF-Werten aktualisieren
    gs_sync_acf_to_latest_revision($post->ID);
}, 20);

// ---------------------------------------------------------------------------
// 4b. Classic Editor / WP-Admin: Nach dem ACF-Save dasselbe
// ---------------------------------------------------------------------------

add_action('acf/save_post', function ($post_id) {
    if (!is_numeric($post_id) || get_post_type((int) $post_id) !== 'spot') {
        return;
    }
    wp_save_post_revision((int) $post_id);
    gs_sync_acf_to_latest_revision((int) $post_id);
}, 20);

// ---------------------------------------------------------------------------
// 5. Revisionswiederherstellung: ACF-Felder zurückschreiben
// ---------------------------------------------------------------------------

add_action('wp_restore_post_revision', function (int $post_id, int $revision_id) {
    if (get_post_type($post_id) !== 'spot') {
        return;
    }
    foreach (array_keys(GS_ACF_FIELDS) as $field_key) {
        $value = get_post_meta($revision_id, $field_key, true);
        if ($value !== '' && $value !== false) {
            update_post_meta($post_id, $field_key, $value);
        } else {
            delete_post_meta($post_id, $field_key);
        }
    }
}, 10, 2);
