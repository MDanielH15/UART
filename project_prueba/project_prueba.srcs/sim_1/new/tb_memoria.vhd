library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mod15_ram_tb is
end mod15_ram_tb;

architecture Behavioral of mod15_ram_tb is

    -- Componente a probar
    component mod15_ram
        Port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            salida  : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Señales internas para conectar al DUT (Device Under Test)
    signal clk_tb     : std_logic := '0';
    signal reset_tb   : std_logic := '0';
    signal salida_tb  : std_logic_vector(3 downto 0);

begin

    -- Instancia del DUT
    uut: mod15_ram
        port map (
            clk     => clk_tb,
            reset   => reset_tb,
            salida  => salida_tb
        );

    -- Generación del reloj: período de 10 ns (100 MHz)
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for 5 ns;
            clk_tb <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Estímulos de prueba
    stim_proc: process
    begin
        -- Inicio con reset activo
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';

        -- Simular durante 160 ns para ver 16 ciclos (de 0 a 14 y de nuevo a 0)
        wait for 160 ns;

        -- Finaliza simulación
        wait;
    end process;

end Behavioral;
