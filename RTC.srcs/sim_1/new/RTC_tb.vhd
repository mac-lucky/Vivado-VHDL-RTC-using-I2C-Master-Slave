


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_unsigned.ALL;use std.textio.all;
use ieee.std_logic_textio.all;
use IEEE.STD_LOGIC_unsigned.ALL;

entity RTC_tb is
--  Port ( );
end RTC_tb;


architecture Behavioral of RTC_tb is

    type STATES is (Idle,Start,Addressing,S_Ack1,S_Ack2,M_Ack,Read,Write,Stop);
    signal STATE : STATES := Idle;

    signal data_clk, data_clk_prev : std_logic; --zegar lini SDA i jego stan poprzedni
    signal scl_clk : std_logic; --wewnetrzny zegar scl
    signal scl_ena : std_logic := '0';  --przekazywanie wewnetrznego scl na wyjscie
    signal sda_int : std_logic := '1';  --wewnetrzna linia sda
    signal sda_ena_n : std_logic;   --przekazywanie wew. sda na wyjscie
    signal address_s : std_logic_vector(7 downto 0); --sygna³ przechowujacy podany adres i bit R/W
    signal data_rd_s, data_wr_s: std_logic_vector(7 downto 0); --sygnal przechowuj¹cy dane do odczytu/zapisu
    signal index : integer range 0 to 7 := 7; --sygnal do zliczania bitow
    signal sync : std_logic := '0';

	component i2cmaster is
	PORT ( CLK : in std_logic;     --zegar 50MHz
        R_n : in std_logic;     --reset aktywowany stanem niskim
        ENA : in std_logic;     --aktywowanie wys³ania/odebrania danych
        ADDRESS : in std_logic_vector(7 downto 0);      --adres slave; bit 0 to bit R/W
        DATA_WR : in std_logic_vector(7 downto 0);      --dane do zapisu
        DATA_RD : out std_logic_vector(7 downto 0);     --dane odczytane
        ACK_ERROR : buffer std_logic;      --b³¹d przy odczytywaniu bitów ack
        BUSY : out std_logic;           --sygnalizacja zajêcia
        SDA : inout std_logic;
        SCL : inout std_logic);
	end component;


begin
    stim_proc : process
    begin
	
	--opisanie linii
	   assert false severity failure;
    end process stim_proc;

    rtc_fsm : process(CLK)
    begin
	   state <= state_next;
    end process rtc_fsm;

--sprawdzanie stanow 
    rtc: process
    begin
	   case state is
		when IDLE =>
			if(R_n = '1') then
				state_next <= IDLE;
				wait for clk_period;
			elsif(SDA = '0' and SCL = '1') then
				state_next <= Read_Address;
				wait for clk_period;
			else
				state_next <= IDLE;
				wait for clk_period;
			end if;
		when Read_Address =>
			address_s(BIT_INDEX) <= SDA;
			if(BIT_INDEX > 0) then
				state_next <= Read_Address;
				wait for clk_period;
			else
				case address_s is 
					when "00010001" =>
						state_next <= GetHr;
						wait for clk_period; 
					when "00011011" =>
						state_next <= GetMin;
						wait for clk_period;
					when "00100111" =>
						state_next <= GetSec;
						wait for clk_period;
					when "00010000" =>
						state_next <= SetHr;
						wait for clk_period;
					when "00011010" =>
						state_next <= SetMin;
						wait for clk_period;
					when "00100110" =>
						state_next <= SetSec;
						wait for clk_period;
					when others =>
						state_next <= IDLE;
				end case;
			end if;
		when GetHr =>
			DATA <= Hr;
			SDA <= '0';
			SDA <= DATA(BIT_INDEX);
			if(BIT_INDEX > 0) then
				state_next <= GetHr;
				wait for clk_period;
			else
				stat_next <= IDLE;
				wait for clk_period;
			end if;
		when GetMin =>
			DATA <= Min;
			SDA <= '0';
			SDA <= DATA(BIT_INDEX);
			if(BIT_INDEX > 0) then
				state_next <= GetMin;
				wait for clk_period;
			else
				state_next <= IDLE;
				wait for clk_period;
			end if;
		when GetSec =>
			DATA <= Sec;
			SDA <= '0';
			SDA <= DATA(BIT_INDEX);
			if(BIT_INDEX > 0) then
				state_next <= GetSec;
				wait for clk_period;
			else
				state_next <= IDLE;
				wait for clk_period;
			end if;
	end case;
end process rtc;



uut:RTC
	PORT MAP (
	clk => clk;
	R_n => R_n;
	BUSY => BUSY;
	ADDRESS => ADDRESS;
	DATA_WR => DATA_WR;
	DATA_RD => DATA_RD;
	ENA_n => ENA_n;
	SDA => SDA;
	SCL => SCL);


end Behavioral;