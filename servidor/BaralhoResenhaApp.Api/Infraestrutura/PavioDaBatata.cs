namespace BaralhoResenhaApp.Api.Infraestrutura;

/// <summary>
/// Batata quente: o pavio é segredo do servidor, então nenhum celular sabe a hora
/// de perguntar. A cada segundo o servidor confere as salas e, onde a batata
/// estourou, avisa a turma pelo tempo real.
/// </summary>
public sealed class PavioDaBatata(SalasEmMemoria salas, NotificadorTempoReal notificador, TimeProvider relogio)
    : BackgroundService
{
    internal static readonly TimeSpan Intervalo = TimeSpan.FromSeconds(1);

    protected override async Task ExecuteAsync(CancellationToken cancelamento)
    {
        using var temporizador = new PeriodicTimer(Intervalo, relogio);
        while (await temporizador.WaitForNextTickAsync(cancelamento))
            notificador.Publicar(salas.ConferirBatatas());
    }
}
