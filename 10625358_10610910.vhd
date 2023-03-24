----------------------------------------------------------------------------------
-- Progetto: Reti Logiche
-- Studenti: Arturo Caliandro e Vincenzo Converso
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is port (

    i_clk   : in std_logic;  --segnale di clock generato dal test
    i_rst   : in std_logic;  --segnale di reset che inizializza la macchina al primo segnale di start
    i_start : in std_logic;  -- segnale di start generato dal test
    i_data  : in std_logic_vector(7 downto 0); --quando faccio una lettura da memoria il byte che ho chiesto arriva da qua
    o_address : out std_logic_vector(15 downto 0); --indirizzo inviato alla memoria di quello che voglio leggere/scrivere
    o_done : out std_logic; --indica la fine dell'elaborazione  e il dato di uscita scritto in memoria
    o_en : out std_logic; --quando voglio fare un ciclo di lettura o scrittura della memoria metto ad 1
    o_we : out std_logic; --disambiguatore tra scrivere 1 e leggere 0 sulla memoria
    o_data : out std_logic_vector (7 downto 0)  --quando voglio scrivere sulla memoria
    );
   
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is 

    type state_type is (reset_state, wait_state, get_line_state, get_column_state, read_state, get_last_p_state,
                        check_curr_p_address, check_p_value, get_shift_value, get_pixel, new_p_state, write_state);
    signal state_reg, state_next : state_type;
    --indirizzi importanti
    constant first_pixel_address : std_logic_vector := "0000000000000010";
    constant num_column_address : std_logic_vector := "0000000000000000";
    constant num_lines_address : std_logic_vector := "0000000000000001";
    
    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
    signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
    signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
        
    signal pixel_max, pixel_max_next : std_logic_vector(7 downto 0) := "00000000";
    signal pixel_min, pixel_min_next : std_logic_vector(7 downto 0) := "11111111";
    signal column,column_next,lines, lines_next : std_logic_vector(7 downto 0) := "00000000";
    signal current_pixel_address, current_pixel_address_next, last_pixel_address, equalized_pixel_address,last_pixel_address_next, equalized_pixel_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
    signal shift_level, shift_level_next : std_logic_vector(3 downto 0);
    signal wait_flag, wait_flag_next : std_logic_vector(2 downto 0) := "000";
    signal current_p_value, current_p_value_next: std_logic_vector(7 downto 0);
    signal shifted_pixel, shifted_pixel_next: std_logic_vector(15 downto 0);

	begin
    	process(i_clk, i_rst)
    	begin

        if(i_rst = '1') then
            pixel_max <= "00000000";
            pixel_min <= "11111111";
            current_pixel_address <= "0000000000000010";
            state_reg <= reset_state;
        elsif (rising_edge(i_clk)) then
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= o_address_next;
            
            column <= column_next;
            lines <= lines_next;
            pixel_max <= pixel_max_next;
            pixel_min <= pixel_min_next;
            wait_flag <= wait_flag_next;
            current_pixel_address <= current_pixel_address_next;
            last_pixel_address <= last_pixel_address_next;
            equalized_pixel_address <= equalized_pixel_address_next;
            shift_level <= shift_level_next;
            current_p_value <= current_p_value_next;
            shifted_pixel <= shifted_pixel_next;
            
            state_reg <= state_next;
        end if;
	end process;
	process(state_reg, i_data, wait_flag, i_start, pixel_max, pixel_min, current_p_value, current_pixel_address,
	           last_pixel_address, equalized_pixel_address, shift_level, shifted_pixel)
	begin
        o_done_next <= '0';
        o_en_next <= '0';
        o_we_next <= '0';
        o_data_next <= "00000000";
        o_address_next <= "0000000000000000";
        
        column_next <= column;
        lines_next <= lines;
        pixel_max_next <= pixel_max;
        pixel_min_next <= pixel_min;
        current_pixel_address_next <= current_pixel_address;
        last_pixel_address_next <= last_pixel_address;
        equalized_pixel_address_next <= equalized_pixel_address;
        shift_level_next <= shift_level; 
        wait_flag_next <= wait_flag;
        current_p_value_next <= current_p_value;
        shifted_pixel_next <= shifted_pixel;
        
        state_next <= state_reg;
        
        case state_reg is
            when reset_state =>
                if(i_start = '1') then
                    state_next <= get_column_state;
                end if;  
            when wait_state =>
                if (wait_flag = "000") then
                    state_next <= get_line_state;
                elsif (wait_flag = "100") then
                    if (i_start = '0') then
                        pixel_max_next <= "00000000";
                        pixel_min_next <= "11111111";
                        current_pixel_address_next <= "0000000000000010";
                        o_done_next <= '0';
                        state_next <= reset_state;
                    else state_next <= wait_state;
                    end if;  
                else state_next <= read_state;
                end if;
            when read_state =>
                if (wait_flag = "001") then
                    if (i_data = "00000000") then
                        wait_flag_next <= "100";
                        o_done_next <= '1';
                        state_next <= wait_state;
                    else
                        lines_next <= i_data;
                        state_next <= get_last_p_state;
                    end if;
                elsif (wait_flag = "010") then
                    current_p_value_next <= i_data;
                    state_next <= check_p_value;
                elsif (wait_flag = "011") then
                    current_p_value_next <= i_data;
                    state_next <= new_p_state;
                end if;
            when get_column_state =>
                o_en_next <= '1';
                o_we_next <= '0';
                o_address_next <= num_column_address;
                wait_flag_next <= "000";
                state_next <= wait_state;
            when get_line_state =>
                if (i_data = "00000000") then
                    wait_flag_next <= "100";
                    o_done_next <= '1';
                else 
                    column_next <= i_data;
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= num_lines_address;
                    wait_flag_next <= "001";
                end if;
                state_next <= wait_state;
            when get_last_p_state =>
                last_pixel_address_next <= std_logic_vector(unsigned(lines) * unsigned(column) + "00000001");
                equalized_pixel_address_next <= std_logic_vector(unsigned(lines) * unsigned(column) + "00000010");
                state_next <= check_curr_p_address;
            when check_curr_p_address =>
                if((pixel_min = "00000000" and pixel_max = "11111111") or (current_pixel_address > last_pixel_address)) then
                    current_pixel_address_next <= first_pixel_address;
                    state_next <= get_shift_value;                    
                else 
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= current_pixel_address;
                    wait_flag_next <= "010";
                    state_next <= wait_state;
                end if;
            when check_p_value =>
                if (current_p_value < pixel_min) then
                    pixel_min_next <= current_p_value;
                end if;
                if (current_p_value > pixel_max) then
                    pixel_max_next <= current_p_value;
                end if;
                current_pixel_address_next <= std_logic_vector(unsigned(current_pixel_address) + "0000000000000001");
                state_next <= check_curr_p_address;
            when get_shift_value =>
                if (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") = "00000001") then
                    shift_level_next <= "1000";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "00000100") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "00000010")) then
                    shift_level_next <= "0111";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "00001000") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "00000100")) then
                    shift_level_next <= "0110";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "00010000") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "00001000")) then
                    shift_level_next <= "0101";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "00100000") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "00010000")) then
                    shift_level_next <= "0100";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "01000000") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "00100000")) then
                    shift_level_next <= "0011";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") < "10000000") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "01000000")) then
                    shift_level_next <= "0010";
                elsif ((std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") <= "11111111") and
                        (std_logic_vector(unsigned(pixel_max) - unsigned(pixel_min) + "00000001") >= "10000000")) then
                    shift_level_next <= "0001";
                else shift_level_next <= "0000";
                end if;
                state_next <= get_pixel;
            when get_pixel =>
                if (current_pixel_address <= last_pixel_address) then
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= current_pixel_address;
                    current_pixel_address_next <= std_logic_vector(unsigned(current_pixel_address) + "0000000000000001");
                    wait_flag_next <= "011";
                    state_next <= wait_state;
                else wait_flag_next <= "100";
                    o_done_next <= '1';
                    state_next <= wait_state;
                end if;
            when new_p_state => 
                if (shift_level = "0001") then
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "00000010");
                elsif (shift_level = "0010") then
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "00000100");
                elsif (shift_level = "0011") then
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "00001000");
                elsif (shift_level = "0100") then
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "00010000");
                elsif (shift_level = "0101") then  
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "00100000"); 
                elsif (shift_level = "0110") then 
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "01000000");  
                elsif (shift_level = "0111") then
                shifted_pixel_next <= std_logic_vector((unsigned(current_p_value) - unsigned(pixel_min)) * "10000000");
                elsif (shift_level = "0000") then
                shifted_pixel_next <= std_logic_vector(unsigned(current_p_value) * "00000001");
                else shifted_pixel_next <= "0000000000000000";                             
                end if;
                state_next <= write_state;
            when write_state => 
                o_en_next <= '1';
                o_we_next <= '1';
                o_address_next <= equalized_pixel_address;
                if (shifted_pixel <= "0000000011111111") then
                    o_data_next <= shifted_pixel(7 downto 0);
                else o_data_next <= "11111111";
                end if;
                equalized_pixel_address_next <= std_logic_vector(unsigned(equalized_pixel_address) + "00000001");
                state_next <= get_pixel;
        end case;                            
    end process;   
 end Behavioral;
