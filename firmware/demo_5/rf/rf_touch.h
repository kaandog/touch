/** @file rf_touch.h
 *  @brief rf touch packet defs
 */

typedef struct touch_packet {
    char cmd;
    uint8_t data;
    uint8_t node_id;
} touch_packet;

