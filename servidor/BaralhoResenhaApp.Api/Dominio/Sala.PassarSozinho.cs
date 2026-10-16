namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Passar a carta sozinho: quando todo mundo responde (no Beba se, "Me pegou"
/// ou "Não me pegou") ou marca "Pronto" depois da revelação, a carta passa
/// em 3 segundos. Quem criou a sala não fica sobrecarregado. Qualquer um pode
/// segurar; aí só quem criou a sala passa.
/// </summary>
public sealed partial class Sala
{
    internal static readonly TimeSpan TempoParaPassar = TimeSpan.FromSeconds(3);

    /// <summary>Celulares chegam alguns milissegundos antes da hora: tolera um pouco.</summary>
    private static readonly TimeSpan Folga = TimeSpan.FromMilliseconds(300);

    public void MarcarPronto(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is FaseDaSala.Lobby or FaseDaSala.Fim) return;
            if (!PodeFicarPronto(Rodada!)) throw new AcaoNaoPermitidaException("Responda a carta primeiro.");
            Rodada!.Prontos.Add(jogador.Id);
            ConferirProntos();
            Tocar();
        }
    }

    /// <summary>"Segura aí": para a contagem; a carta só passa pela mão de quem criou a sala.</summary>
    public void Segurar(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            Rodada!.SeguradaPor = jogador.Nome;
            Rodada.PassaEm = null;
            Tocar();
        }
    }

    /// <summary>
    /// Quando a contagem acaba, cada celular pede para passar; o primeiro passa e
    /// os outros chegam numa rodada que já mudou, sem efeito.
    /// </summary>
    public void PassarSozinho(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is FaseDaSala.Lobby or FaseDaSala.Fim) return;
            if (Rodada!.PassaEm is not { } quando || _relogio.GetUtcNow() < quando - Folga) return;
            AvancarCarta();
            Tocar();
        }
    }

    /// <summary>Milissegundos até passar sozinho; nulo sem contagem.</summary>
    internal int? RestanteParaPassar(Rodada rodada) =>
        rodada.PassaEm is { } quando
            ? (int)Math.Max(0, Math.Round((quando - _relogio.GetUtcNow()).TotalMilliseconds))
            : null;

    /// <summary>
    /// Pronto vale quando não há mais o que responder: depois da revelação (no
    /// Casais em Jogo, depois do julgamento) ou nas cartas que não pedem resposta.
    /// </summary>
    private bool PodeFicarPronto(Rodada rodada) => Fase == FaseDaSala.Revelada
        ? rodada.Carta.Modo != ModoDeJogo.CasaisEmJogo || rodada.Acertou is not null
        : rodada.Carta.Modo switch
        {
            ModoDeJogo.BebaSe or ModoDeJogo.RegraRelampago or ModoDeJogo.Elogios => true,
            // Aponta no 3: não tem resposta no celular.
            ModoDeJogo.MaisProvavel => !rodada.Votacao,
            _ => false
        };

    private void ConferirProntos()
    {
        if (Rodada is not { } rodada || !Configuracao.PassarSozinho) return;
        if (rodada.SeguradaPor is not null || rodada.PassaEm is not null) return;
        if (_jogadores.Count > 0 && _jogadores.All(j => rodada.Prontos.Contains(j.Id)))
            rodada.PassaEm = _relogio.GetUtcNow() + TempoParaPassar;
    }

    private void AvancarCarta()
    {
        if (Rodada!.Carta.Modo != ModoDeJogo.RegraRelampago) GastarUmaCartaDaRegra();
        Distribuir();
    }
}
