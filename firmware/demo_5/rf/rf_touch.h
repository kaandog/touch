/** @file rf_touch.h
 *  @brief rf touch packet defs
 */

#define TIMEOUT_CNT 100

#define TOUCH_ERROR -1
#define TOUCH_SUCCESS 0

#define MAX_NODES   3
#define LOW_BATTERY_THRESHOLD   450
#define BATTERY_ALERT_CNT   10

typedef struct touch_packet_t {
    char cmd;
    uint8_t src_node_id;
    uint8_t dest_node_id;
    int16_t data;
} touch_packet_t;


#define CMD_ACK         'a'
#define CMD_POSITION    'p'
#define CMD_MOVE        'm'
#define CMD_LOWPOWER    'l'
#define CMD_QUESTION    'q'
#define CMD_INFO        'i'
#define CMD_NOTFOUND    'e'
#define CMD_WAKEUP      'w'
#define CMD_DANGER      'd'
#define CMD_NOOP        '0'


#define FALSE   0
#define TRUE    (!FALSE)

void touch_gw_main(void);
void touch_node_main(void);
uint8_t touch_schedule_cmd(char cmd, int16_t data, uint8_t dest_id);
uint8_t touch_tx_pkt(touch_packet_t pkt);
uint8_t touch_build_and_tx(char cmd, int16_t data, uint8_t dest_id);
uint8_t touch_tx_with_auto_retry(char cmd, int16_t data, uint8_t dest_id, uint8_t retry_cnt);
uint8_t touch_tx_with_ack(char cmd, int16_t data, uint8_t dest_id);
void touch_init(uint8_t is_gw);
