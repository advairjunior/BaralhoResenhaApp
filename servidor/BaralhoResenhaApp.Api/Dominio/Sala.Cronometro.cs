namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Cronômetro da carta ("em 5 segundos", mímica de 60 s): quem criou a sala
/// dá o "valendo" e todos os celulares contam o mesmo tempo.
/// </summary>
public sealed partial class Sala
{
    public void IniciarCronometro(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Quem dá o valendo é quem criou a sala.");
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            var segundos = Rodada!.SegundosDoCronometro
                ?? throw new AcaoNaoPermitidaException("Esta carta não tem cronômetro.");
            // Tocar de novo recomeça: na rodada de "cada um em 5 segundos", é um valendo por pessoa.
            Rodada.CronometroAte = _relogio.GetUtcNow().AddSeconds(segundos);
            Tocar();
        }
    }

    /// <summary>Milissegundos que faltam; nulo antes do valendo, zero quando acabou.</summary>
    internal int? RestanteDoCronometro(Rodada rodada) =>
        rodada.CronometroAte is { } ate
            ? (int)Math.Max(0, Math.Round((ate - _relogio.GetUtcNow()).TotalMilliseconds))
            : null;
}
