namespace BaralhoResenhaApp.Api.Infraestrutura;

/// <summary>
/// O plano free do Render dorme depois de 15 min sem acesso, e dormir apaga as salas.
/// Na pausa da pizza os celulares ficam bloqueados e não consultam nada, então é o
/// próprio servidor que se cutuca pelo endereço público enquanto houver sala em jogo.
/// Sem sala, ele para de cutucar e o servidor dorme normalmente.
/// </summary>
public sealed class MantemAcordado(
    SalasEmMemoria salas,
    HttpClient cliente,
    string? enderecoPublico,
    TimeProvider relogio,
    ILogger<MantemAcordado> registro) : BackgroundService
{
    internal static readonly TimeSpan Intervalo = TimeSpan.FromMinutes(10);

    public async Task<bool> CutucarSePreciso(CancellationToken cancelamento)
    {
        if (string.IsNullOrWhiteSpace(enderecoPublico) || !salas.TemSalaEmJogo()) return false;
        try
        {
            using var resposta = await cliente.GetAsync(
                $"{enderecoPublico.TrimEnd('/')}/api/saude", cancelamento);
        }
        catch (Exception erro) when (erro is HttpRequestException or TaskCanceledException
                                     && !cancelamento.IsCancellationRequested)
        {
            registro.LogWarning("Não consegui me cutucar: {Mensagem}", erro.Message);
        }
        return true;
    }

    protected override async Task ExecuteAsync(CancellationToken cancelamento)
    {
        if (string.IsNullOrWhiteSpace(enderecoPublico)) return;
        using var temporizador = new PeriodicTimer(Intervalo, relogio);
        while (await temporizador.WaitForNextTickAsync(cancelamento))
            await CutucarSePreciso(cancelamento);
    }
}
