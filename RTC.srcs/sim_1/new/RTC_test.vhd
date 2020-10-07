library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RTC is
end RTC;

architecture Behavioral of RTC is

    constant SYSCLK_PERIOD : time := 100 ns; 
    constant SCL_period : time := 5000 ns; -- 400KHz 

    signal SYSCLK : std_logic := '0';
    signal NSYSRESET : std_logic := '0';
    
    signal stop_the_clock: boolean;

    component RTC
        -- ports
        port( 
            -- Inputs
            CLK : in std_logic;
            R_n : in std_logic;
            ADDRESS : in std_logic_vector(7 downto 0);
            DATA_WR : in std_logic_vector(7 downto 0);
            ENA_n : in std_logic;

            -- Outputs
            BUSY : out std_logic;
            DATA_RD : out std_logic_vector(7 downto 0);

            -- Inouts
            SDA : inout std_logic;
            SCL : inout std_logic

        );
        
    end component;
    
--    component i2c_slave
--        -- ports
--        port( 
--                        -- Inouts
--            SDA : inout std_logic;
--            SCL : inout std_logic

--        );
        
--    end component;
    
    
   
    
    
    signal CLK : std_logic;
    signal R_n : std_logic;
    signal ADDRESS : std_logic_vector(7 downto 0);
    signal DATA_WR : std_logic_vector(7 downto 0);
    signal ENA_n : std_logic;

    signal BUSY : std_logic;
    signal DATA_RD : std_logic_vector(7 downto 0);

    signal SDA : std_logic;
    signal SCL : std_logic;
    
begin

    process
        variable vhdl_initial : BOOLEAN := TRUE;

    begin
        if ( vhdl_initial ) then
            -- Assert Reset
            NSYSRESET <= '0';
            wait for ( SYSCLK_PERIOD * 10 );
            
            NSYSRESET <= '1';
            wait;
        end if;
    end process;

    -- Clock Driver
    SYSCLK <= not SYSCLK after (SYSCLK_PERIOD / 2.0 );

    -- Instantiate Unit Under Test:  i2c_master
   
        
     --   port map( 
            -- Inputs
        --    CLK => SYSCLK,
        --    R_n => R_n,
        --    ADDRESS => (others=> '0'),
        --    DATA_WR => (others=> '0'),
         --   ENA_n => ENA_n,

            -- Outputs
         --   BUSY =>  BUSY,
         --   DATA_RD => DATA_RD,

            -- Inouts
         --   SDA =>  SDA,
         --   SCL =>  SCL

    --    );
    
--    i2c_slave_1 : i2c_slave
        
--        port map(
        
--        SDA => SDA,
--        SCL => SCL
        
--        );
    
  process
  begin
    
    
    
   
    
    R_n <= '0';
    wait for 2500 ns;
    ADDRESS <= "00010001";
    wait for 2500 ns;
--    ADDRESS <= "00010000";
--    wait for 2500 ns;
    

--    SDA <= '0';
--    wait for 50 ns;
--    SDA <= '1';
--    wait for 7250 ns;  
    
    
    
    
  end process;

     process
     begin
      while not stop_the_clock loop
        SCL <='1';
        wait for 1250 ns;
        SCL <='0';
        wait for 1250 ns;
      end loop;
      wait;
    end process;


end Behavioral;
