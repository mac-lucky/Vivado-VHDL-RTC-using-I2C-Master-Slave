library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RTC_tb is
end RTC_tb;

architecture Behavioral of RTC_tb is

    
     component RTC
        -- porty
        port( 
            -- wejscia
            CLK : in std_logic;
            R_n : in std_logic;
            ADDRESS : in std_logic_vector(7 downto 0);
            DATA_WR : in std_logic_vector(7 downto 0);
            ENA : in std_logic;

            -- wyjscia
            BUSY : out std_logic;
            DATA_RD : out std_logic_vector(7 downto 0);

            -- wejscia/wyjscia
            SDA : inout std_logic;
            SCL : inout std_logic

        );
        
    end component;
    
    --signaly
   signal CLK : std_logic := '0';
   signal R_n : std_logic := '0';
   signal ENA : std_logic := '0';
   signal ADDRESS : std_logic_vector(7 downto 0) := (others => '0');
   signal DATA_WR : std_logic_vector(7 downto 0) := (others => '0');

	
   signal SDA : std_logic;
   signal SCL : std_logic;

 
   signal DATA_RD : std_logic_vector(7 downto 0);
   signal ACK_ERROR : std_logic;
   signal BUSY : std_logic;

   -- zegar
   constant CLK_period : time := 10 ns;
   

--type STATES is (Idle,Start,Addressing,S_Ack1,S_Ack2,M_Ack,Read,Write,Stop);
--signal STATE, nextSTATE : STATES := Idle;
    
--signal index : integer range 0 to 7 := 7; --sygnal do zliczania bitow
--signal address_s : std_logic_vector(7 downto 0);
    
   
    
begin


    -- port mapa rtc
    uut: RTC PORT MAP (
          CLK => CLK,
          R_n => R_n,
          ENA => ENA,
          ADDRESS => ADDRESS,
          DATA_WR => DATA_WR,
          DATA_RD => DATA_RD,
          BUSY => BUSY,
          SDA => SDA,
          SCL => SCL
        );
        
  
  -- proces zegara
  clk_proc : process
  begin
      CLK <= '0';
      wait for clk_period;
      CLK <= '1';
      wait for clk_period;
  
  end process clk_proc;  
    
  --proces symulacji
  sim : process
    begin
        R_n <= '0';
        wait for CLK_period;
        R_n <= '1';
        ADDRESS <= "00010000"; -- zapis
        DATA_WR <= "10011001"; -- podana wartosc danych do zapisania
        ENA <= '1';
        wait for clk_period*2500;
        ADDRESS <= "00010001"; -- odczyt
        DATA_WR <= "10011000";
        ENA <= '1';
        wait for clk_period*5000; 
        ENA <= '0';
        wait for clk_period*500;
        assert false severity failure;
  end process sim;


end Behavioral;
