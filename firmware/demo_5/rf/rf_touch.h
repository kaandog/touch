/** @file rf_touch.h
 *  @brief rf touch packet defs
 */

typedef struct touch_packet_t {
    char cmd;
    int8_t data;
    int8_t node_id;
} touch_packet_t;

