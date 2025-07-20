
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity transmitter is
    port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        transmit : in STD_LOGIC;
        data : in STD_LOGIC_VECTOR(7 downto 0);
        TxD : out STD_LOGIC;
        bussy : out std_logic
    );
end transmitter;

architecture Behavioral of transmitter is
    signal bitcounter : INTEGER range 0 to 10 := 0;
    signal counter : INTEGER range 0 to 10415 := 0;
    signal state, nextstate : STD_LOGIC := '0';
    signal rightshiftreg : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal shift, load, clear : STD_LOGIC := '0';
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= '0';
                counter <= 0;
                bitcounter <= 0;
            else
                counter <= counter + 1;
                if counter >= 10415 then
                    state <= nextstate;
                    counter <= 0;
                    if load = '1' then
                        rightshiftreg <= '1' & data & '0';
                    end if;
                    if clear = '1' then
                        bitcounter <= 0;
                    end if;
                    if shift = '1' then
                        rightshiftreg <= '0' & rightshiftreg(9 downto 1);
                        bitcounter <= bitcounter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            load <= '0'; shift <= '0'; clear <= '0'; TxD <= '1';
            case state is
                when '0' =>
                    bussy <= '0';
                    if transmit = '1' then
                        nextstate <= '1'; load <= '1';
                    else
                        nextstate <= '0';
                        TxD <= '1';
                    end if;
                when '1' =>
                    bussy <= '1';
                    if bitcounter >= 10 then
                        nextstate <= '0'; clear <= '1';
                    else
                        nextstate <= '1';
                        TxD <= rightshiftreg(0);
                        shift <= '1';
                    end if;
                when others =>
                    nextstate <= '0';
            end case;
        end if;
    end process;

end Behavioral;
