/** @file rf_touch.h
 *  @brief rf touch packet defs
 */

#define TIMEOUT_CNT 100

#define TOUCH_ERROR -1
#define TOUCH_SUCCESS 0

#define MAX_NODES   3

typedef struct touch_packet_t {
    char cmd;
    uint8_t src_node_id;
    uint8_t dest_node_id;
    int16_t data;
} touch_packet_t;


uint8_t touch_tx(char cmd, int16_t data, uint8_t dest_id);
uint8_t touch_tx_with_auto_retry(char cmd, int16_t data, uint8_t dest_id, uint8_t retry_cnt);
uint8_t touch_tx_with_ack(char cmd, int16_t data, uint8_t dest_id);
void touch_init(uint8_t is_gw);
