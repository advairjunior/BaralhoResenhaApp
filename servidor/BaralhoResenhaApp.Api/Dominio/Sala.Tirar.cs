namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>"👎 Tira essa": a carta sai do baralho da noite e vem outra.</summary>
public sealed partial class Sala
{
    private readonly HashSet<string> _tiradas = [];

    /// <summary>Quem tirou a carta anterior; aparece só na carta seguinte.</summary>
    public string? CartaTiradaPor { get; private set; }

    public void Tirar(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = ExigirAnfitriao(token, SoQuemCriouPuxaCarta);
            if (Fase is FaseDaSala.Lobby or FaseDaSala.Fim || !RodadaEmAndamento(numeroDaRodada)) return;
            var carta = Rodada!.Carta;
            _tiradas.Add(carta.Id);
            jogador.Estatisticas.Tiradas++;
            // Regra-relâmpago tirada não vale mais.
            if (carta.Modo == ModoDeJogo.RegraRelampago) Regra = null;
            else GastarUmaCartaDaRegra();
            Distribuir();
            CartaTiradaPor = jogador.Nome;
            Tocar();
        }
    }
}
