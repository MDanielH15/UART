library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM_MOD15_RAM is
    Port (
        clk     : in  STD_LOGIC;
        rst     : in  STD_LOGIC;
        write_en: in  STD_LOGIC;
        addr_wr : in  STD_LOGIC_VECTOR(3 downto 0);  -- Dirección para escribir
        data_wr : in  STD_LOGIC_VECTOR(3 downto 0);  -- Valor a escribir
        state_out : out STD_LOGIC_VECTOR(3 downto 0)
    );
end FSM_MOD15_RAM;

architecture Behavioral of FSM_MOD15_RAM is
    type RAM_type is array (0 to 15) of STD_LOGIC_VECTOR(3 downto 0);
    signal RAM : RAM_type := (
        0  => "0001", -- Estado 0 -> 1
        1  => "0010", -- Estado 1 -> 2
        2  => "0011", -- Estado 2 -> 3
        3  => "0100", -- ...
        4  => "0101",
        5  => "0110",
        6  => "0111",
        7  => "1000",
        8  => "1001",
        9  => "1010",
        10 => "1011",
        11 => "1100",
        12 => "1101",
        13 => "1110",
        14 => "1111",
        15 => "0000"  -- Estado 15 -> 0
    );

    signal current_state : STD_LOGIC_VECTOR(3 downto 0) := "0000";
begin
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= "0000";
        elsif rising_edge(clk) then
            if write_en = '1' then
                RAM(to_integer(unsigned(addr_wr))) <= data_wr;
            else
                current_state <= RAM(to_integer(unsigned(current_state)));
            end if;
        end if;
    end process;

    state_out <= current_state;
end Behavioral;
